package database

import (
	"embed"
	"fmt"

	"github.com/pressly/goose/v3"
)

//go:embed migrations/*.sql
var embedMigrations embed.FS

func (db *DB) Migrate() error {
	goose.SetBaseFS(embedMigrations)

	err := goose.SetDialect("sqlite3")
	if err != nil {
		return fmt.Errorf("failed to set goose dialect to sqlite3: %w", err)
	}

	return goose.Up(db.DB, "migrations")
}
