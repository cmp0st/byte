package storage

import (
	"errors"
	"fmt"
	"log/slog"

	"github.com/cmp0st/byte/internal/config"
)

func NewFromConfig(c config.Storage) (Interface, error) {
	var fs Interface
	switch {
	case c.InMemory != nil:
		fs = NewInMemory()
		slog.Info("Storage backend initialized", "type", "in-memory")
	case c.Posix != nil:
		fs = NewPosix(c.Posix.Root)
		slog.Info("Storage backend initialized",
			"type", "posix",
			"root", c.Posix.Root)
	case c.S3 != nil:
		s3Fs, err := NewS3(*c.S3)
		if err != nil {
			slog.Error("Failed to create S3 filesystem",
				"error", err,
				"bucket", c.S3.Bucket,
				"region", c.S3.Region)
			return nil, fmt.Errorf("failed to create S3 filesystem: %w", err)
		}
		fs = s3Fs
		slog.Info("Storage backend initialized",
			"type", "s3",
			"bucket", c.S3.Bucket,
			"region", c.S3.Region)
	default:
		slog.Error("No storage backend configured")
		return nil, errors.New("no storage configured")
	}
	return fs, nil
}
