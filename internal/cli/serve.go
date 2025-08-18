package cli

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/charmbracelet/ssh"
	"github.com/cmp0st/byte/internal/config"
	"github.com/cmp0st/byte/internal/sftp"
	"github.com/cmp0st/byte/internal/storage"
	"github.com/spf13/cobra"
)

func NewServeCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "serve",
		Short: "run the byte server",
		RunE:  serve,
	}
}

func serve(cmd *cobra.Command, args []string) error {
	conf, err := config.Load()
	if err != nil {
		return fmt.Errorf("Failed to load config: %v", err)
	}

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

	slog.Info("Configuration loaded successfully")

	store, err := storage.NewFromConfig(conf.Storage)
	if err != nil {
		slog.Error("failed to load storage backend", "err", err)
		return err
	}
	s, err := sftp.NewServer(conf.SFTP, &sftp.Handlers{
		Storage: store,
	})
	if err != nil {
		slog.Error("Failed to create SSH server", "error", err)
		return fmt.Errorf("failed to create SSH server: %w", err)
	}

	done := make(chan os.Signal, 1)
	signal.Notify(done, os.Interrupt, syscall.SIGINT, syscall.SIGTERM)

	slog.Info("Starting SSH server", "address", fmt.Sprintf("%s:%d", conf.SFTP.Host, conf.SFTP.Port))

	go func() {
		if err = s.ListenAndServe(); err != nil && !errors.Is(err, ssh.ErrServerClosed) {
			slog.Error("Failed to start server", "error", err)
			return
		}
	}()

	<-done
	slog.Info("Shutdown signal received, stopping server gracefully")

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer func() { cancel() }()
	if err := s.Shutdown(ctx); err != nil && !errors.Is(err, ssh.ErrServerClosed) {
		slog.Error("Failed to shutdown server gracefully", "error", err)
		return fmt.Errorf("failed to shutdown server: %w", err)
	}

	slog.Info("Server stopped successfully")
	return nil
}
