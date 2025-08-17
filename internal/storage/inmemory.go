package storage

import "github.com/spf13/afero"

func NewInMemory() Interface {
	return afero.NewMemMapFs()
}
