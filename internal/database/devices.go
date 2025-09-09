package database

import (
	"context"
	"fmt"
	"log/slog"

	"github.com/cmp0st/byte/internal/logging"
)

func (db *DB) AddDevice(ctx context.Context, id string) error {
	_, err := db.ExecContext(ctx, "INSERT INTO devices (id) VALUES (?)", id)
	if err != nil {
		logging.FromContext(ctx).Error(
			"failed to insert device",
			slog.Any("err", err),
		)

		return fmt.Errorf("failed to insert device: %w", err)
	}

	return nil
}

func (db *DB) ListDevices(ctx context.Context) ([]string, error) {
	rows, err := db.QueryContext(ctx, "SELECT id FROM devices")
	if err != nil {
		logging.FromContext(ctx).Error(
			"failed to list devices",
			slog.Any("err", err),
		)

		return nil, fmt.Errorf("failed to list devices: %w", err)
	}
	//nolint: errcheck
	defer rows.Close()

	var (
		id  string
		ids []string
	)

	for rows.Next() {
		if rows.Err() != nil {
			logging.FromContext(ctx).Error(
				"failed to read row",
				slog.Any("err", err),
			)

			return nil, fmt.Errorf("failed to read row while listing devices: %w", err)
		}

		err = rows.Scan(&id)
		if err != nil {
			logging.FromContext(ctx).Error(
				"failed to scan row",
				slog.Any("err", err),
			)

			return nil, fmt.Errorf("failed to scan row for device id: %w", err)
		}

		ids = append(ids, id)
	}

	return ids, nil
}

func (db *DB) DeleteDevice(ctx context.Context, id string) error {
	_, err := db.ExecContext(ctx, "DELETE FROM devices WHERE id=?", id)
	if err != nil {
		logging.FromContext(ctx).Error(
			"failed to delete device",
			slog.Any("err", err),
		)

		return fmt.Errorf("failed to delete device: %w", err)
	}

	return nil
}
