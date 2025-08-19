package api

import (
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"

	"connectrpc.com/connect"
	"github.com/spf13/afero"

	"github.com/cmp0st/byte/gen/files/v1"
	"github.com/cmp0st/byte/gen/files/v1/filesv1connect"
	"github.com/cmp0st/byte/internal/storage"
)

// FileService implements the files v1 service
type FileService struct {
	storage storage.Interface
}

// NewFileService creates a new file service
func NewFileService(storage storage.Interface) *FileService {
	return &FileService{
		storage: storage,
	}
}

// ListDirectory lists the contents of a directory
func (s *FileService) ListDirectory(ctx context.Context, req *connect.Request[filesv1.ListDirectoryRequest]) (*connect.Response[filesv1.ListDirectoryResponse], error) {
	entries, err := afero.ReadDir(s.storage, req.Msg.Path)
	if err != nil {
		return nil, connect.NewError(connect.CodeNotFound, fmt.Errorf("failed to list directory: %w", err))
	}

	var directoryEntries []*filesv1.DirectoryEntry
	for _, entry := range entries {
		fileInfo := &filesv1.FileInfo{
			Name:         entry.Name(),
			Path:         filepath.Join(req.Msg.Path, entry.Name()),
			Size:         entry.Size(),
			Mode:         uint32(entry.Mode()),
			ModifiedTime: nil, // TODO: Convert time
			IsDir:        entry.IsDir(),
		}
		directoryEntries = append(directoryEntries, &filesv1.DirectoryEntry{
			FileInfo: fileInfo,
		})
	}

	return connect.NewResponse(&filesv1.ListDirectoryResponse{
		Entries: directoryEntries,
	}), nil
}

// ReadFile reads file content as a stream
func (s *FileService) ReadFile(ctx context.Context, req *connect.Request[filesv1.ReadFileRequest], stream *connect.ServerStream[filesv1.ReadFileResponse]) error {
	file, err := s.storage.Open(req.Msg.Path)
	if err != nil {
		return connect.NewError(connect.CodeNotFound, fmt.Errorf("failed to open file: %w", err))
	}
	defer file.Close()

	// Handle offset if provided
	offset := int64(0)
	if req.Msg.Offset != nil {
		offset = *req.Msg.Offset
		if _, err := file.Seek(offset, io.SeekStart); err != nil {
			return connect.NewError(connect.CodeInvalidArgument, fmt.Errorf("failed to seek: %w", err))
		}
	}

	// Create a limited reader if limit is provided
	var reader io.Reader = file
	if req.Msg.Limit != nil {
		reader = io.LimitReader(file, *req.Msg.Limit)
	}

	// Stream file content in chunks
	buffer := make([]byte, 64*1024) // 64KB chunks
	currentOffset := offset

	for {
		n, err := reader.Read(buffer)
		if n > 0 {
			chunk := &filesv1.StreamChunk{
				Data:   buffer[:n],
				Offset: currentOffset,
			}
			if err := stream.Send(&filesv1.ReadFileResponse{
				Chunk: chunk,
			}); err != nil {
				return connect.NewError(connect.CodeInternal, fmt.Errorf("failed to send chunk: %w", err))
			}
			currentOffset += int64(n)
		}

		if err == io.EOF {
			break
		}
		if err != nil {
			return connect.NewError(connect.CodeInternal, fmt.Errorf("failed to read file: %w", err))
		}
	}

	return nil
}

// WriteFile writes file content from a stream
func (s *FileService) WriteFile(ctx context.Context, stream *connect.ClientStream[filesv1.WriteFileRequest]) (*connect.Response[filesv1.WriteFileResponse], error) {
	var file afero.File
	var totalBytes int64
	var metadata *filesv1.WriteFileMetadata

	defer func() {
		if file != nil {
			file.Close()
		}
	}()

	for stream.Receive() {
		req := stream.Msg()

		if req.GetMetadata() != nil {
			// First message should contain metadata
			if metadata != nil {
				return nil, connect.NewError(connect.CodeInvalidArgument, errors.New("metadata already received"))
			}
			metadata = req.GetMetadata()

			// Create parent directories if requested
			if metadata.CreateParents {
				dir := filepath.Dir(metadata.Path)
				if err := s.storage.MkdirAll(dir, 0755); err != nil {
					return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("failed to create parent directories: %w", err))
				}
			}

			// Open/create the file
			var err error
			file, err = s.storage.OpenFile(metadata.Path, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, os.FileMode(metadata.Mode))
			if err != nil {
				return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("failed to create file: %w", err))
			}
		} else if chunk := req.GetChunk(); chunk != nil {
			// Write chunk data
			if file == nil {
				return nil, connect.NewError(connect.CodeInvalidArgument, errors.New("no metadata received before chunk"))
			}

			n, err := file.Write(chunk.Data)
			if err != nil {
				return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("failed to write chunk: %w", err))
			}
			totalBytes += int64(n)
		}
	}

	if err := stream.Err(); err != nil {
		return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("stream error: %w", err))
	}

	if metadata == nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, errors.New("no metadata received"))
	}

	return connect.NewResponse(&filesv1.WriteFileResponse{
		BytesWritten: totalBytes,
	}), nil
}

// CreateDirectory creates a directory
func (s *FileService) CreateDirectory(ctx context.Context, req *connect.Request[filesv1.CreateDirectoryRequest]) (*connect.Response[filesv1.CreateDirectoryResponse], error) {
	var err error
	if req.Msg.CreateParents {
		err = s.storage.MkdirAll(req.Msg.Path, os.FileMode(req.Msg.Mode))
	} else {
		err = s.storage.Mkdir(req.Msg.Path, os.FileMode(req.Msg.Mode))
	}

	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("failed to create directory: %w", err))
	}

	return connect.NewResponse(&filesv1.CreateDirectoryResponse{}), nil
}

// DeletePath deletes a file or directory
func (s *FileService) DeletePath(ctx context.Context, req *connect.Request[filesv1.DeletePathRequest]) (*connect.Response[filesv1.DeletePathResponse], error) {
	var err error
	if req.Msg.Recursive {
		err = s.storage.RemoveAll(req.Msg.Path)
	} else {
		err = s.storage.Remove(req.Msg.Path)
	}

	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("failed to delete path: %w", err))
	}

	return connect.NewResponse(&filesv1.DeletePathResponse{}), nil
}

// MovePath moves/renames a file or directory
func (s *FileService) MovePath(ctx context.Context, req *connect.Request[filesv1.MovePathRequest]) (*connect.Response[filesv1.MovePathResponse], error) {
	err := s.storage.Rename(req.Msg.FromPath, req.Msg.ToPath)
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("failed to move path: %w", err))
	}

	return connect.NewResponse(&filesv1.MovePathResponse{}), nil
}

// GetPathInfo gets information about a file or directory
func (s *FileService) GetPathInfo(ctx context.Context, req *connect.Request[filesv1.GetPathInfoRequest]) (*connect.Response[filesv1.GetPathInfoResponse], error) {
	info, err := s.storage.Stat(req.Msg.Path)
	if err != nil {
		return nil, connect.NewError(connect.CodeNotFound, fmt.Errorf("failed to stat path: %w", err))
	}

	fileInfo := &filesv1.FileInfo{
		Name:         info.Name(),
		Path:         req.Msg.Path,
		Size:         info.Size(),
		Mode:         uint32(info.Mode()),
		ModifiedTime: nil, // TODO: Convert time
		IsDir:        info.IsDir(),
	}

	return connect.NewResponse(&filesv1.GetPathInfoResponse{
		FileInfo: fileInfo,
	}), nil
}

// Ensure FileService implements the interface
var _ filesv1connect.FileServiceHandler = (*FileService)(nil)