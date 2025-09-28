package auth

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"aidanwoods.dev/go-paseto"
	"connectrpc.com/connect"
	"github.com/cmp0st/byte/internal/database"
	"github.com/cmp0st/byte/internal/key"
	"github.com/cmp0st/byte/internal/logging"
)

// NB: Tokens are minted per-rpc request so we have very short
// expiration per token to mitigate replay attacks in the case of a
// token leak.
const DefaultTokenExpiration = 30 * time.Second

func NewClientInterceptor(chain key.ClientChain) connect.UnaryInterceptorFunc {
	interceptor := func(next connect.UnaryFunc) connect.UnaryFunc {
		return connect.UnaryFunc(func(
			ctx context.Context,
			req connect.AnyRequest,
		) (connect.AnyResponse, error) {
			// Client implementation
			if !req.Spec().IsClient {
				return nil, errors.New("cannot use client auth interceptor on server")
			}

			token, err := chain.Token()
			if err != nil {
				return nil, connect.NewError(
					connect.CodeFailedPrecondition,
					fmt.Errorf("failed to generate token: %w", err),
				)
			}

			req.Header().Set("Authorization", "Bearer "+*token)
			req.Header().Set("Device-ID", chain.ClientID)

			return next(ctx, req)
		})
	}

	return connect.UnaryInterceptorFunc(interceptor)
}

func NewServerInterceptor(chain key.ServerChain, db *database.DB) connect.UnaryInterceptorFunc {
	interceptor := func(next connect.UnaryFunc) connect.UnaryFunc {
		return connect.UnaryFunc(func(
			ctx context.Context,
			req connect.AnyRequest,
		) (connect.AnyResponse, error) {
			logger := logging.FromContext(ctx)

			authHeader := req.Header().Get(`Authorization`)

			tokenStr, found := strings.CutPrefix(authHeader, "Bearer ")
			if !found {
				return nil, connect.NewError(
					connect.CodeUnauthenticated,
					errors.New(`unauthenticated`),
				)
			}

			clientID := req.Header().Get(`Device-ID`)
			if clientID == "" {
				logger.ErrorContext(ctx, "server auth interceptor: missing client id header")

				return nil, connect.NewError(
					connect.CodeUnauthenticated,
					errors.New(`unauthenticated`),
				)
			}

			clientChain, err := chain.ClientChain(clientID)
			if err != nil {
				logger.ErrorContext(ctx, "server auth interceptor: failed to load client chain",
					slog.String("device_id", clientID),
					slog.Any("err", err))

				return nil, connect.NewError(
					connect.CodeUnauthenticated,
					errors.New(`unauthenticated`),
				)
			}

			tokenKey, err := clientChain.TokenKey()
			if err != nil {
				logger.ErrorContext(
					ctx,
					"server auth interceptor: failed to derive client token key",
					slog.String("device_id", clientID),
					slog.Any("err", err),
				)

				return nil, connect.NewError(
					connect.CodeUnauthenticated,
					errors.New("unauthenticated"),
				)
			}

			token, err := paseto.NewParserForValidNow().
				ParseV4Local(*tokenKey, tokenStr, []byte(clientID))
			if err != nil {
				return nil, connect.NewError(
					connect.CodeUnauthenticated,
					errors.New("unauthenticated"),
				)
			}

			// NB: It is important to check device existence here only
			// after the token is authenticated to prevent pre-auth data
			// from touching the database layer
			ok, err := db.DeviceExists(ctx, clientID)
			if err != nil {
				logger.ErrorContext(
					ctx,
					"failed to check if device exists",
					slog.Any("err", err),
				)

				return nil, connect.NewError(
					connect.CodeUnauthenticated,
					errors.New("unauthenticated"),
				)
			}

			if !ok {
				logger.WarnContext(
					ctx,
					"device does not exist",
					slog.String("device_id", clientID),
				)

				return nil, connect.NewError(
					connect.CodeUnauthenticated,
					errors.New("unauthenticated"),
				)
			}

			// TODO: check additional claims like audience here perhaps. At this point though we've checked time
			// and clientID and that is sufficient
			_ = token

			ctx = WithDevice(ctx, clientID)

			return next(ctx, req)
		})
	}

	return connect.UnaryInterceptorFunc(interceptor)
}
