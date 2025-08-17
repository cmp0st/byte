package cli

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/charmbracelet/ssh"
	"github.com/charmbracelet/wish"
	"github.com/cmp0st/byte/internal/config"
	internalsftp "github.com/cmp0st/byte/internal/sftp"
	"github.com/cmp0st/byte/internal/storage"
	"github.com/pkg/sftp"
	"github.com/spf13/afero"
	"github.com/spf13/cobra"
	gossh "golang.org/x/crypto/ssh"
)

func NewServeCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "serve",
		Short: "run the byte server",
		RunE:  serve,
	}
}

func isAuthorizedKey(authorizedKeys []string, key ssh.PublicKey) bool {
	keyType := key.Type()
	keyFingerprint := gossh.FingerprintSHA256(key)

	if len(authorizedKeys) == 0 {
		slog.Warn("Authentication denied: no authorized keys configured", "key_type", keyType, "fingerprint", keyFingerprint)
		return false
	}

	keyData := key.Marshal()

	for i, authKey := range authorizedKeys {
		parts := strings.Fields(authKey)
		if len(parts) < 2 {
			slog.Debug("Skipping malformed authorized key", "index", i)
			continue
		}

		parsedKey, _, _, _, err := gossh.ParseAuthorizedKey([]byte(authKey))
		if err != nil {
			slog.Debug("Failed to parse authorized key", "index", i, "error", err)
			continue
		}

		if parsedKey.Type() == keyType && string(parsedKey.Marshal()) == string(keyData) {
			slog.Info("Authentication successful", "key_type", keyType, "fingerprint", keyFingerprint)
			return true
		}
	}

	slog.Warn("Authentication denied: key not found in authorized keys", "key_type", keyType, "fingerprint", keyFingerprint)
	return false
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

	var fs afero.Fs
	switch {
	case conf.InMemory != nil:
		fs = storage.NewInMemory()
		slog.Info("Storage backend initialized", "type", "in-memory")
	case conf.Posix != nil:
		fs = storage.NewPosix(conf.Posix.Root)
		slog.Info("Storage backend initialized", "type", "posix", "root", conf.Posix.Root)
	case conf.S3 != nil:
		s3Fs, err := storage.NewS3(storage.S3Config{
			Bucket:    conf.S3.Bucket,
			Region:    conf.S3.Region,
			Endpoint:  conf.S3.Endpoint,
			AccessKey: conf.S3.AccessKey,
			SecretKey: conf.S3.SecretKey,
			UseSSL:    conf.S3.UseSSL,
		})
		if err != nil {
			slog.Error("Failed to create S3 filesystem", "error", err, "bucket", conf.S3.Bucket, "region", conf.S3.Region)
			return fmt.Errorf("failed to create S3 filesystem: %w", err)
		}
		fs = s3Fs
		slog.Info("Storage backend initialized", "type", "s3", "bucket", conf.S3.Bucket, "region", conf.S3.Region)
	default:
		slog.Error("No storage backend configured")
		return errors.New("no storage configured")
	}

	s, err := wish.NewServer(
		wish.WithAddress(fmt.Sprintf("%s:%d", conf.Host, conf.Port)),
		wish.WithHostKeyPEM([]byte(conf.HostKey)),
		wish.WithPublicKeyAuth(func(ctx ssh.Context, key ssh.PublicKey) bool {
			return isAuthorizedKey(conf.AuthorizedKeys, key)
		}),
		wish.WithSubsystem("sftp", func(sess ssh.Session) {
			remoteAddr := sess.RemoteAddr().String()
			user := sess.User()

			slog.Info("SFTP session started", "user", user, "remote_addr", remoteAddr)

			s := internalsftp.NewServer(fs)
			handlers := sftp.Handlers{
				FileGet:  s,
				FilePut:  s,
				FileCmd:  s,
				FileList: s,
			}

			server := sftp.NewRequestServer(sess, handlers)
			if err := server.Serve(); err != nil {
				slog.Error("SFTP server error", "error", err, "user", user, "remote_addr", remoteAddr)
			} else {
				slog.Info("SFTP session ended", "user", user, "remote_addr", remoteAddr)
			}
		}),
	)
	if err != nil {
		slog.Error("Failed to create SSH server", "error", err)
		return fmt.Errorf("failed to create SSH server: %w", err)
	}

	done := make(chan os.Signal, 1)
	signal.Notify(done, os.Interrupt, syscall.SIGINT, syscall.SIGTERM)

	slog.Info("Starting SSH server", "address", fmt.Sprintf("%s:%d", conf.Host, conf.Port))

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
