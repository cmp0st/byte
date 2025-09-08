package storage

import (
	"errors"
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
	default:
		slog.Error("No storage backend configured")

		return nil, errors.New("no storage configured")
	}

	return fs, nil
}
