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

func (s *FileService) RemoveDirectory(
	ctx context.Context,
	req *connect.Request[filesv1.RemoveDirectoryRequest],
) (*connect.Response[filesv1.RemoveDirectoryResponse], error) {
	logger := logging.FromContext(ctx)

	var err error
	if req.Msg.GetRecursive() {
		err = s.storage.RemoveAll(req.Msg.GetPath())
	} else {
		err = s.storage.Remove(req.Msg.GetPath())
	}

	if err != nil {
		logger.Error("failed to create directory", slog.Any("err", err))
		// We just assume an invalid argument here, but there are plenty of
		// other reasons this could fail.
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}

	return connect.NewResponse(&filesv1.RemoveDirectoryResponse{}), nil
}

// ReadFile reads the contents of a file.
func (s *FileService) ReadFile(
	ctx context.Context,
	req *connect.Request[filesv1.ReadFileRequest],
) (*connect.Response[filesv1.ReadFileResponse], error) {
	logger := logging.FromContext(ctx)

	data, err := afero.ReadFile(s.storage, req.Msg.GetPath())
	if err != nil {
		logger.Error("failed to read file", slog.Any("err", err))

		return nil, connect.NewError(
			connect.CodeNotFound,
			fmt.Errorf("failed to read file: %w", err),
		)
	}

	fileInfo, err := s.storage.Stat(req.Msg.GetPath())
	if err != nil {
		logger.Error("failed to stat file", slog.Any("err", err))

		return nil, connect.NewError(
			connect.CodeNotFound,
			fmt.Errorf("failed to stat file: %w", err),
		)
	}

	return connect.NewResponse(&filesv1.ReadFileResponse{
		Data: data,
		Info: &filesv1.FileInfo{
			Name:         fileInfo.Name(),
			Path:         req.Msg.GetPath(),
			Size:         fileInfo.Size(),
			ModifiedTime: timestamppb.New(fileInfo.ModTime()),
			IsDir:        fileInfo.IsDir(),
		},
	}), nil
}

// WriteFile writes data to a file.
func (s *FileService) WriteFile(
	ctx context.Context,
	req *connect.Request[filesv1.WriteFileRequest],
) (*connect.Response[filesv1.WriteFileResponse], error) {
	logger := logging.FromContext(ctx)

	// Create parent directories if requested
	if req.Msg.GetCreateParents() {
		dir := filepath.Dir(req.Msg.GetPath())

		err := s.storage.MkdirAll(dir, DefaultDirectoryPermission)
		if err != nil {
			logger.Error("failed to create parent directories", slog.Any("err", err))

			return nil, connect.NewError(
				connect.CodeInvalidArgument,
				fmt.Errorf("failed to create parent directories: %w", err),
			)
		}
	}

	// Write the file
	err := afero.WriteFile(s.storage, req.Msg.GetPath(), req.Msg.GetData(), DefaultFilePermission)
	if err != nil {
		logger.Error("failed to write file", slog.Any("err", err))

		return nil, connect.NewError(
			connect.CodeInternal,
			fmt.Errorf("failed to write file: %w", err),
		)
	}

	// Get file info
	fileInfo, err := s.storage.Stat(req.Msg.GetPath())
	if err != nil {
		logger.Error("failed to stat file after write", slog.Any("err", err))

		return nil, connect.NewError(
			connect.CodeInternal,
			fmt.Errorf("failed to stat file: %w", err),
		)
	}

	return connect.NewResponse(&filesv1.WriteFileResponse{
		Info: &filesv1.FileInfo{
			Name:         fileInfo.Name(),
			Path:         req.Msg.GetPath(),
			Size:         fileInfo.Size(),
			ModifiedTime: timestamppb.New(fileInfo.ModTime()),
			IsDir:        fileInfo.IsDir(),
		},
	}), nil
}

// DeleteFile deletes a file or directory.
func (s *FileService) DeleteFile(
	ctx context.Context,
	req *connect.Request[filesv1.DeleteFileRequest],
) (*connect.Response[filesv1.DeleteFileResponse], error) {
	logger := logging.FromContext(ctx)

	var err error
	if req.Msg.GetRecursive() {
		err = s.storage.RemoveAll(req.Msg.GetPath())
	} else {
		err = s.storage.Remove(req.Msg.GetPath())
	}

	if err != nil {
		logger.Error("failed to delete file", slog.Any("err", err))

		return nil, connect.NewError(
			connect.CodeNotFound,
			fmt.Errorf("failed to delete file: %w", err),
		)
	}

	return connect.NewResponse(&filesv1.DeleteFileResponse{}), nil
}
