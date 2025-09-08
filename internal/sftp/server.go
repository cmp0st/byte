package sftp

import (
	"context"
	"fmt"
	"log/slog"

	"github.com/charmbracelet/ssh"
	"github.com/charmbracelet/wish"
	"github.com/cmp0st/byte/internal/auth"
	"github.com/cmp0st/byte/internal/config"
	"github.com/cmp0st/byte/internal/key"
	"github.com/cmp0st/byte/internal/logging"
	"github.com/cmp0st/byte/internal/storage"
	"github.com/pkg/sftp"
)

func NewServer(
	ctx context.Context,
	c config.SFTP,
	s storage.Interface,
	k key.ServerChain,
) (*ssh.Server, error) {
	logger := logging.FromContext(ctx)

	raw, err := k.SSHHostKey()
	if err != nil {
		return nil, err
	}

	hostKeyPEM, err := key.ToPEM(raw)
	if err != nil {
		return nil, err
	}

	middleware := logging.SSHMiddleware(logger)
	//nolint: contextcheck
	sftpHandler := func(sess ssh.Session) {
		logger := logging.FromContext(sess.Context())
		h := &Handlers{
			Storage: s,
			Logger:  logger,
		}

		handlers := sftp.Handlers{
			FileGet:  h,
			FilePut:  h,
			FileCmd:  h,
			FileList: h,
		}

		server := sftp.NewRequestServer(sess, handlers)

		err := server.Serve()
		if err != nil {
			logger.Error("sftp server error", slog.Any("err", err))
		} else {
			logger.Info("sftp session ended")
		}
	}

	return wish.NewServer(
		wish.WithAddress(fmt.Sprintf("%s:%d", c.Host, c.Port)),
		wish.WithHostKeyPEM(hostKeyPEM),
		// NB: this middleware is only invoked on the default handler and it
		// is bypassed on the subsystem and request handlers. It is set here to
		// cover future functionality related to SSH
		wish.WithMiddleware(logging.SSHMiddleware(logger)),
		//nolint: contextcheck
		wish.WithPublicKeyAuth(auth.SSHPublicKey(c.AuthorizedKeys)),
		wish.WithSubsystem("sftp", ssh.SubsystemHandler(middleware(sftpHandler))),
	)
}
