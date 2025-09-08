package logging

import (
	"log/slog"
	"os"

	"github.com/cmp0st/byte/internal/config"
)

func NewFromConfig(conf config.Server) *slog.Logger {
	var level slog.Level

	switch conf.LogLevel {
	case "DEBUG":
		level = slog.LevelDebug
	case "INFO":
		level = slog.LevelInfo
	case "WARN":
		level = slog.LevelWarn
	case "ERROR":
		level = slog.LevelError
	}

	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: level,
	}))

	slog.SetDefault(logger)

	return logger
}
