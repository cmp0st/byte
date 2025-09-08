package server

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
	"github.com/cmp0st/byte/internal/api"
	"github.com/cmp0st/byte/internal/config"
	"github.com/cmp0st/byte/internal/key"
	"github.com/cmp0st/byte/internal/logging"
	"github.com/cmp0st/byte/internal/sftp"
	"github.com/cmp0st/byte/internal/storage"
	oklogrun "github.com/oklog/run"
	"github.com/spf13/cobra"
)

func newRunCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "run",
		Short: "run the byte server",
		RunE:  run,
	}
}

const DefaultShutdownGracePeriod = 30 * time.Second

func run(cmd *cobra.Command, args []string) error {
	conf, err := config.LoadServer()
	if err != nil {
		return fmt.Errorf("failed to load config: %w", err)
	}

	keychain, err := key.NewServerChain([]byte(conf.Secret))
	if err != nil {
		return err
	}

	logger := logging.NewFromConfig(*conf)

	store, err := storage.NewFromConfig(conf.Storage)
	if err != nil {
		return err
	}

	// Create SFTP server
	sftpServer, err := sftp.NewServer(conf.SFTP, &sftp.Handlers{
		Storage: store,
	}, *keychain)
	if err != nil {
		return fmt.Errorf("failed to create SSH server: %w", err)
	}

	// Create HTTP API server
	apiServer, err := api.NewServer(
		store,
		*keychain,
		logger,
		fmt.Sprintf("%s:%d", conf.HTTP.Host, conf.HTTP.Port),
	)
	if err != nil {
		return fmt.Errorf("misconfigured api server: %w", err)
	}

	var g oklogrun.Group

	// Add SFTP server
	g.Add(sftpServer.ListenAndServe, func(error) {
		ctx, cancel := context.WithTimeout(
			context.Background(),
			DefaultShutdownGracePeriod,
		)
		defer cancel()

		err := sftpServer.Shutdown(ctx)
		if err != nil && !errors.Is(err, ssh.ErrServerClosed) {
			slog.Error("Failed to shutdown SFTP server gracefully", "error", err)
		}
	})

	// Add HTTP API server
	g.Add(apiServer.Start, func(error) {
		err := apiServer.Stop()
		if err != nil {
			slog.Error("Failed to shutdown HTTP server gracefully", "error", err)
		}
	})

	// Add signal handler
	g.Add(func() error {
		c := make(chan os.Signal, 1)
		signal.Notify(c, syscall.SIGINT, syscall.SIGTERM)
		sig := <-c

		return fmt.Errorf("received signal %s", sig)
	}, func(error) {
	})

	err = g.Run()
	if err != nil {
		slog.Info("Services stopped", "reason", err.Error())
	}

	return nil
}
