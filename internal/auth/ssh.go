package auth

import (
	"log/slog"
	"strings"

	"github.com/charmbracelet/ssh"
	"github.com/cmp0st/byte/internal/logging"
	gossh "golang.org/x/crypto/ssh"
)

const (
	// At a mininum an SSH key has the key type and key value fields and then optionally
	// the host.
	SSHKeyMinFields = 2
)

func SSHPublicKey(authorizedKeys []string) func(ctx ssh.Context, key ssh.PublicKey) bool {
	return func(ctx ssh.Context, key ssh.PublicKey) bool {
		keyType := key.Type()
		keyFingerprint := gossh.FingerprintSHA256(key)

		logger := logging.FromContext(ctx).With(
			slog.String("key_type", keyType),
			slog.String("fingerprint", keyFingerprint),
		)

		if len(authorizedKeys) == 0 {
			logger.Warn("authentication denied: no authorized keys configured")

			return false
		}

		keyData := key.Marshal()

		for i, authKey := range authorizedKeys {
			parts := strings.Fields(authKey)
			if len(parts) < SSHKeyMinFields {
				logger.Debug(
					"skipping malformed authorized key",
					slog.Int("index", i),
				)

				continue
			}

			parsedKey, _, _, _, err := gossh.ParseAuthorizedKey([]byte(authKey))
			if err != nil {
				logger.Debug(
					"failed to parse authorized key",
					slog.Int("index", i),
					slog.Any("error", err),
				)

				continue
			}

			if parsedKey.Type() == keyType && string(parsedKey.Marshal()) == string(keyData) {
				logger.Info("Authentication successful")

				return true
			}
		}

		logger.Warn("Authentication denied: key not found in authorized keys")

		return false
	}
}
