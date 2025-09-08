package api

import (
	"context"
	"fmt"
	"log/slog"
	"path/filepath"
	"time"

	"connectrpc.com/connect"
	"github.com/spf13/afero"
	"google.golang.org/protobuf/types/known/timestamppb"

	filesv1 "github.com/cmp0st/byte/gen/files/v1"
	"github.com/cmp0st/byte/gen/files/v1/filesv1connect"
	"github.com/cmp0st/byte/internal/storage"
)

// FileService implements the files v1 service.
type FileService struct {
	storage storage.Interface
}

// NewFileService creates a new file service.
func NewFileService(storage storage.Interface) filesv1connect.FileServiceHandler {
	return &FileService{
		storage: storage,
	}
}

// ListDirectory lists the contents of a directory.
func (s *FileService) ListDirectory(
	ctx context.Context,
	req *connect.Request[filesv1.ListDirectoryRequest],
) (*connect.Response[filesv1.ListDirectoryResponse], error) {
	start := time.Now()
	slog.Debug("API: ListDirectory request", "path", req.Msg.Path)

	if req.Msg.GetPath() == "" {
		// Default to root
		req.Msg.Path = "."
	}
	entries, err := afero.ReadDir(s.storage, req.Msg.Path)
	if err != nil {
		slog.Error(
			"API: Failed to list directory",
			"path", req.Msg.Path,
			"error", err,
			"duration", time.Since(start),
		)

		return nil, connect.NewError(
			connect.CodeNotFound,
			fmt.Errorf("failed to list directory: %w", err),
		)
	}

	var directoryEntries []*filesv1.FileInfo
	for _, entry := range entries {
		fileInfo := &filesv1.FileInfo{
			Name:         entry.Name(),
			Path:         filepath.Join(req.Msg.Path, entry.Name()),
			Size:         entry.Size(),
			ModifiedTime: timestamppb.New(entry.ModTime()),
			IsDir:        entry.IsDir(),
		}
		directoryEntries = append(directoryEntries, fileInfo)
	}

	slog.Info("API: Directory listed successfully",
		"path", req.Msg.Path,
		"entries", len(directoryEntries),
		"duration", time.Since(start))

	return connect.NewResponse(&filesv1.ListDirectoryResponse{
		Entries: directoryEntries,
	}), nil
}
