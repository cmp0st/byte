package logging

import (
	"log/slog"

	"github.com/charmbracelet/ssh"
	"github.com/charmbracelet/wish"
)

func SSHContextWith(ctx ssh.Context, logger *slog.Logger) {
	// ssh.Context is a weird mutable version of context.Context
	ctx.SetValue(loggerKey{}, logger)
}

func SSHMiddleware(logger *slog.Logger) wish.Middleware {
	return func(next ssh.Handler) ssh.Handler {
		return func(sess ssh.Session) {
			ctx := sess.Context()

			sessionLogger := logger.With(
				slog.String("user", ctx.User()),
				slog.String("client_ver", ctx.ClientVersion()),
				slog.String("server_ver", ctx.ServerVersion()),
				slog.String("sess_id", ctx.SessionID()),
				slog.Any("local_addr", ctx.LocalAddr()),
				slog.Any("remote_addr", ctx.RemoteAddr()),
			)

			// Mutate session context with logger
			SSHContextWith(ctx, sessionLogger)

			next(sess)
		}
	}
}
