package storage

import "github.com/spf13/afero"

func NewPosix(rootPath string) Interface {
	return afero.NewBasePathFs(afero.NewOsFs(), rootPath)
}
