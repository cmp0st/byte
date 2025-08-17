package cli

import (
	"context"
	"errors"
	"fmt"
	"log"
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
	if len(authorizedKeys) == 0 {
		// Fail closed if no keys
		return false
	}

	keyData := key.Marshal()
	keyType := key.Type()

	for _, authKey := range authorizedKeys {
		parts := strings.Fields(authKey)
		if len(parts) < 2 {
			continue
		}

		parsedKey, _, _, _, err := gossh.ParseAuthorizedKey([]byte(authKey))
		if err != nil {
			continue
		}

		if parsedKey.Type() == keyType && string(parsedKey.Marshal()) == string(keyData) {
			return true
		}
	}

	return false
}

func serve(cmd *cobra.Command, args []string) error {
	conf, err := config.Load()
	if err != nil {
		return fmt.Errorf("Failed to load config: %v", err)
	}

	var fs afero.Fs
	switch {
	case conf.InMemory != nil:
		fs = storage.NewInMemory()
	case conf.Posix != nil:
		fs = storage.NewPosix(conf.Posix.Root)
	default:
		return errors.New("no storage configured")
	}

	s, err := wish.NewServer(
		wish.WithAddress(fmt.Sprintf("%s:%d", conf.Host, conf.Port)),
		wish.WithHostKeyPEM([]byte(conf.HostKey)),
		wish.WithPublicKeyAuth(func(ctx ssh.Context, key ssh.PublicKey) bool {
			return isAuthorizedKey(conf.AuthorizedKeys, key)
		}),
		wish.WithSubsystem("sftp", func(sess ssh.Session) {
			s := internalsftp.NewServer(fs)
			handlers := sftp.Handlers{
				FileGet:  s,
				FilePut:  s,
				FileCmd:  s,
				FileList: s,
			}

			server := sftp.NewRequestServer(sess, handlers)
			if err := server.Serve(); err != nil {
				log.Printf("SFTP server error: %v", err)
			}
		}),
	)
	if err != nil {
		log.Fatalln(err)
	}

	done := make(chan os.Signal, 1)
	signal.Notify(done, os.Interrupt, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		if err = s.ListenAndServe(); err != nil && !errors.Is(err, ssh.ErrServerClosed) {
			log.Printf("failed to start server: %s", err)
			return
		}
	}()

	<-done
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer func() { cancel() }()
	if err := s.Shutdown(ctx); err != nil && !errors.Is(err, ssh.ErrServerClosed) {
		log.Fatalln(err)
	}
	return nil
}
