package logging

import (
	"context"
	"log/slog"
	"time"

	"connectrpc.com/connect"
)

func NewInterceptor(logger *slog.Logger) connect.UnaryInterceptorFunc {
	interceptor := func(next connect.UnaryFunc) connect.UnaryFunc {
		return connect.UnaryFunc(func(
			ctx context.Context,
			req connect.AnyRequest,
		) (connect.AnyResponse, error) {
			start := time.Now()

			requestLogger := logger.With(
				slog.String("procedure", req.Spec().Procedure),
				slog.String("peer_addr", req.Peer().Addr),
			)

			clientID := req.Header().Get(`Client-ID`)
			if clientID != "" {
				requestLogger = requestLogger.With(
					slog.String("client_id", clientID),
				)
			}

			ctx = ContextWith(ctx, requestLogger)

			res, err := next(ctx, req)
			duration := time.Since(start)

			requestLogger = requestLogger.With(
				slog.Duration("duration", duration),
			)
			if err != nil {
				requestLogger.ErrorContext(ctx, "request failed",
					slog.Any("err", err),
				)

				return res, err
			}

			requestLogger.InfoContext(ctx, "request succeeded")

			return res, nil
		})
	}

	return connect.UnaryInterceptorFunc(interceptor)
}
