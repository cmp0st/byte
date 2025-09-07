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
	"github.com/cmp0st/byte/internal/key"
	"github.com/cmp0st/byte/internal/logging"
)

func NewClientInterceptor(chain key.ClientChain) connect.UnaryInterceptorFunc {
	interceptor := func(next connect.UnaryFunc) connect.UnaryFunc {
		return connect.UnaryFunc(func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
			// Client implementation
			if !req.Spec().IsClient {
				return nil, errors.New("cannot use client auth interceptor on server")
			}
			token := paseto.NewToken()
			token.SetExpiration(time.Now().Add(30 * time.Second))
			token.SetIssuedAt(time.Now())
			token.SetNotBefore(time.Now())

			tokenKey, err := chain.TokenKey()
			if err != nil {
				return nil, connect.NewError(connect.CodeFailedPrecondition, fmt.Errorf("client key chain misconfigured: %w", err))
			}

			tokenStr := token.V4Encrypt(*tokenKey, []byte(chain.ClientID))
			req.Header().Set("Authorization", "Bearer "+tokenStr)
			req.Header().Set("Client-ID", chain.ClientID)
			return next(ctx, req)
		})
	}
	return connect.UnaryInterceptorFunc(interceptor)
}

func NewServerInterceptor(chain key.ServerChain) connect.UnaryInterceptorFunc {
	interceptor := func(next connect.UnaryFunc) connect.UnaryFunc {
		return connect.UnaryFunc(func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
			logger := logging.FromContext(ctx)

			tokenStr, found := strings.CutPrefix(req.Header().Get(`Authorization`), "Bearer ")
			if !found {
				logger.ErrorContext(ctx, "missing authorization header")
				return nil, connect.NewError(connect.CodeUnauthenticated, errors.New(`unauthenticated`))
			}
			clientID := req.Header().Get(`Client-ID`)
			if clientID == "" {
				logger.ErrorContext(ctx, "missing client id header")
				return nil, connect.NewError(connect.CodeUnauthenticated, errors.New(`unauthenticated`))
			}

			// TODO: check that this clientID is active by looking up valid devices

			clientChain, err := chain.ClientChain(clientID)
			if err != nil {
				logger.ErrorContext(ctx, "failed to load client chain", slog.Any("err", err))
				return nil, connect.NewError(connect.CodeUnauthenticated, errors.New(`unauthenticated`))
			}

			tokenKey, err := clientChain.TokenKey()
			if err != nil {
				logger.ErrorContext(ctx, "failed to derive client token key", slog.Any("err", err))
				return nil, connect.NewError(connect.CodeUnauthenticated, errors.New("unauthenticated"))
			}

			token, err := paseto.NewParserForValidNow().ParseV4Local(*tokenKey, tokenStr, []byte(clientID))
			if err != nil {
				return nil, connect.NewError(connect.CodeUnauthenticated, errors.New("unauthenticated"))
			}

			_ = token
			// TODO: check additional claims like audience here perhaps. At this point though we've checked time
			// and clientID and that is sufficient

			return next(ctx, req)
		})
	}
	return connect.UnaryInterceptorFunc(interceptor)
}
