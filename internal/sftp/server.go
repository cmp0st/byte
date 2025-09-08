package sftp

import (
	"fmt"
	"log/slog"
	"strings"

	"github.com/charmbracelet/ssh"
	"github.com/charmbracelet/wish"
	"github.com/cmp0st/byte/internal/config"
	"github.com/cmp0st/byte/internal/key"
	"github.com/pkg/sftp"
	gossh "golang.org/x/crypto/ssh"
)

const (
	// At a mininum an SSH key has the key type and key value fields and then optionally
	// the host.
	SSHKeyMinFields = 2
)

func isAuthorizedKey(authorizedKeys []string, key ssh.PublicKey) bool {
	keyType := key.Type()
	keyFingerprint := gossh.FingerprintSHA256(key)

	if len(authorizedKeys) == 0 {
		slog.Warn(
			"Authentication denied: no authorized keys configured",
			"key_type", keyType,
			"fingerprint", keyFingerprint,
		)
		return false
	}

	keyData := key.Marshal()

	for i, authKey := range authorizedKeys {
		parts := strings.Fields(authKey)
		if len(parts) < SSHKeyMinFields {
			slog.Debug("Skipping malformed authorized key", "index", i)
			continue
		}

		parsedKey, _, _, _, err := gossh.ParseAuthorizedKey([]byte(authKey))
		if err != nil {
			slog.Debug("Failed to parse authorized key", "index", i, "error", err)
			continue
		}

		if parsedKey.Type() == keyType && string(parsedKey.Marshal()) == string(keyData) {
			slog.Info(
				"Authentication successful",
				"key_type",
				keyType,
				"fingerprint",
				keyFingerprint,
			)
			return true
		}
	}

	slog.Warn(
		"Authentication denied: key not found in authorized keys",
		"key_type",
		keyType,
		"fingerprint",
		keyFingerprint,
	)
	return false
}

func NewServer(c config.SFTP, h *Handlers, k key.ServerChain) (*ssh.Server, error) {
	raw, err := k.SSHHostKey()
	if err != nil {
		return nil, err
	}
	hostKeyPEM, err := key.ToPEM(raw)
	if err != nil {
		return nil, err
	}

	return wish.NewServer(
		wish.WithAddress(fmt.Sprintf("%s:%d", c.Host, c.Port)),
		wish.WithHostKeyPEM(hostKeyPEM),
		wish.WithPublicKeyAuth(func(ctx ssh.Context, key ssh.PublicKey) bool {
			return isAuthorizedKey(c.AuthorizedKeys, key)
		}),
		wish.WithSubsystem("sftp", func(sess ssh.Session) {
			remoteAddr := sess.RemoteAddr().String()
			user := sess.User()

			slog.Info("SFTP session started", "user", user, "remote_addr", remoteAddr)

			handlers := sftp.Handlers{
				FileGet:  h,
				FilePut:  h,
				FileCmd:  h,
				FileList: h,
			}

			server := sftp.NewRequestServer(sess, handlers)
			if err := server.Serve(); err != nil {
				slog.Error(
					"SFTP server error",
					"error",
					err,
					"user",
					user,
					"remote_addr",
					remoteAddr,
				)
			} else {
				slog.Info("SFTP session ended", "user", user, "remote_addr", remoteAddr)
			}
		}),
	)
}
