package api

import (
	"context"
	"fmt"
	"log/slog"
	"path/filepath"

	"connectrpc.com/connect"
	"github.com/spf13/afero"
	"google.golang.org/protobuf/types/known/timestamppb"

	filesv1 "github.com/cmp0st/byte/gen/files/v1"
	"github.com/cmp0st/byte/gen/files/v1/filesv1connect"
	"github.com/cmp0st/byte/internal/logging"
	"github.com/cmp0st/byte/internal/storage"
)

const (
	DefaultDirectoryPermission = 0o700
	DefaultFilePermission      = 0o600
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
	logger := logging.FromContext(ctx)

	if req.Msg.GetPath() == "" {
		// Default to root
		req.Msg.Path = "."
	}

	entries, err := afero.ReadDir(s.storage, req.Msg.GetPath())
	if err != nil {
		logger.Error("failed to list directory", slog.Any("err", err))

		return nil, connect.NewError(
			connect.CodeNotFound,
			fmt.Errorf("failed to list directory: %w", err),
		)
	}

	directoryEntries := make([]*filesv1.FileInfo, len(entries))
	for i, entry := range entries {
		directoryEntries[i] = &filesv1.FileInfo{
			Name:         entry.Name(),
			Path:         filepath.Join(req.Msg.GetPath(), entry.Name()),
			Size:         entry.Size(),
			ModifiedTime: timestamppb.New(entry.ModTime()),
			IsDir:        entry.IsDir(),
		}
	}

	return connect.NewResponse(&filesv1.ListDirectoryResponse{
		Entries: directoryEntries,
	}), nil
}

func (s *FileService) MakeDirectory(
	ctx context.Context,
	req *connect.Request[filesv1.MakeDirectoryRequest],
) (*connect.Response[filesv1.MakeDirectoryResponse], error) {
	logger := logging.FromContext(ctx)

	var err error
	if req.Msg.GetCreateParents() {
		err = s.storage.MkdirAll(req.Msg.GetPath(), DefaultDirectoryPermission)
	} else {
		err = s.storage.Mkdir(req.Msg.GetPath(), DefaultDirectoryPermission)
	}

	if err != nil {
		logger.Error("failed to create directory", slog.Any("err", err))
		// We just assume an invalid argument here, but there are plenty of
		// other reasons this could fail.
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}

	return connect.NewResponse(&filesv1.MakeDirectoryResponse{}), nil
}
