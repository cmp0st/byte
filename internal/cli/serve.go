package cli

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/charmbracelet/ssh"
	"github.com/oklog/run"
	"github.com/spf13/cobra"

	"github.com/cmp0st/byte/internal/api"
	"github.com/cmp0st/byte/internal/config"
	"github.com/cmp0st/byte/internal/sftp"
	"github.com/cmp0st/byte/internal/storage"
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

	// Create SFTP server
	sftpServer, err := sftp.NewServer(conf.SFTP, &sftp.Handlers{
		Storage: store,
	})
	if err != nil {
		slog.Error("Failed to create SSH server", "error", err)
		return fmt.Errorf("failed to create SSH server: %w", err)
	}

	// Create HTTP API server
	httpAddr := fmt.Sprintf("%s:%d", conf.HTTP.Host, conf.HTTP.Port)
	apiServer := api.NewServer(store, httpAddr)

	var g run.Group

	// Add SFTP server
	{
		g.Add(func() error {
			slog.Info("Starting SFTP server", "address", fmt.Sprintf("%s:%d", conf.SFTP.Host, conf.SFTP.Port))
			if err := sftpServer.ListenAndServe(); err != nil && !errors.Is(err, ssh.ErrServerClosed) {
				return fmt.Errorf("SFTP server failed: %w", err)
			}
			return nil
		}, func(error) {
			ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
			defer cancel()
			if err := sftpServer.Shutdown(ctx); err != nil && !errors.Is(err, ssh.ErrServerClosed) {
				slog.Error("Failed to shutdown SFTP server gracefully", "error", err)
			}
		})
	}

	// Add HTTP API server
	{
		g.Add(func() error {
			slog.Info("Starting HTTP API server", "address", httpAddr)
			if err := apiServer.Start(); err != nil && !errors.Is(err, http.ErrServerClosed) {
				return fmt.Errorf("HTTP server failed: %w", err)
			}
			return nil
		}, func(error) {
			if err := apiServer.Stop(); err != nil {
				slog.Error("Failed to shutdown HTTP server gracefully", "error", err)
			}
		})
	}

	// Add signal handler
	{
		cancelInterrupt := make(chan struct{})
		g.Add(func() error {
			c := make(chan os.Signal, 1)
			signal.Notify(c, syscall.SIGINT, syscall.SIGTERM)
			select {
			case sig := <-c:
				slog.Info("Shutdown signal received", "signal", sig.String())
				return fmt.Errorf("received signal %s", sig)
			case <-cancelInterrupt:
				return nil
			}
		}, func(error) {
			close(cancelInterrupt)
		})
	}

	slog.Info("Starting services")
	if err := g.Run(); err != nil {
		slog.Info("Services stopped", "reason", err.Error())
	}

	slog.Info("All services stopped successfully")
	return nil
}
