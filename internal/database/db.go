package database

import "database/sql"

type DB struct {
	*sql.DB
}
