package api

import (
	"context"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"os"
	"path/filepath"
	"time"

	"connectrpc.com/connect"
	"github.com/spf13/afero"
	"google.golang.org/protobuf/types/known/timestamppb"

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
	start := time.Now()
	slog.Debug("API: ListDirectory request", "path", req.Msg.Path)

	entries, err := afero.ReadDir(s.storage, req.Msg.Path)
	if err != nil {
		slog.Error("API: Failed to list directory", "path", req.Msg.Path, "error", err, "duration", time.Since(start))
		return nil, connect.NewError(connect.CodeNotFound, fmt.Errorf("failed to list directory: %w", err))
	}

	var directoryEntries []*filesv1.DirectoryEntry
	for _, entry := range entries {
		fileInfo := &filesv1.FileInfo{
			Name:         entry.Name(),
			Path:         filepath.Join(req.Msg.Path, entry.Name()),
			Size:         entry.Size(),
			Mode:         uint32(entry.Mode()),
			ModifiedTime: timestamppb.New(entry.ModTime()),
			IsDir:        entry.IsDir(),
		}
		directoryEntries = append(directoryEntries, &filesv1.DirectoryEntry{
			FileInfo: fileInfo,
		})
	}

	slog.Info("API: Directory listed successfully", 
		"path", req.Msg.Path, 
		"entries", len(directoryEntries), 
		"duration", time.Since(start))

	return connect.NewResponse(&filesv1.ListDirectoryResponse{
		Entries: directoryEntries,
	}), nil
}

// ReadFile reads file content as a stream
func (s *FileService) ReadFile(ctx context.Context, req *connect.Request[filesv1.ReadFileRequest], stream *connect.ServerStream[filesv1.ReadFileResponse]) error {
	start := time.Now()
	slog.Debug("API: ReadFile request", "path", req.Msg.Path, "offset", req.Msg.Offset, "limit", req.Msg.Limit)

	file, err := s.storage.Open(req.Msg.Path)
	if err != nil {
		slog.Error("API: Failed to open file for reading", "path", req.Msg.Path, "error", err, "duration", time.Since(start))
		return connect.NewError(connect.CodeNotFound, fmt.Errorf("failed to open file: %w", err))
	}
	defer file.Close()

	// Handle offset if provided
	offset := int64(0)
	if req.Msg.Offset != nil {
		offset = *req.Msg.Offset
		if _, err := file.Seek(offset, io.SeekStart); err != nil {
			slog.Error("API: Failed to seek in file", "path", req.Msg.Path, "offset", offset, "error", err)
			return connect.NewError(connect.CodeInvalidArgument, fmt.Errorf("failed to seek: %w", err))
		}
		slog.Debug("API: File seek completed", "path", req.Msg.Path, "offset", offset)
	}

	// Create a limited reader if limit is provided
	var reader io.Reader = file
	if req.Msg.Limit != nil {
		reader = io.LimitReader(file, *req.Msg.Limit)
		slog.Debug("API: Applied read limit", "path", req.Msg.Path, "limit", *req.Msg.Limit)
	}

	// Stream file content in chunks
	buffer := make([]byte, 64*1024) // 64KB chunks
	currentOffset := offset
	totalBytes := int64(0)
	chunkCount := 0

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
				slog.Error("API: Failed to send chunk", "path", req.Msg.Path, "chunk", chunkCount, "error", err)
				return connect.NewError(connect.CodeInternal, fmt.Errorf("failed to send chunk: %w", err))
			}
			currentOffset += int64(n)
			totalBytes += int64(n)
			chunkCount++
		}

		if err == io.EOF {
			break
		}
		if err != nil {
			slog.Error("API: Failed to read file", "path", req.Msg.Path, "error", err)
			return connect.NewError(connect.CodeInternal, fmt.Errorf("failed to read file: %w", err))
		}
	}

	slog.Info("API: File read completed", 
		"path", req.Msg.Path, 
		"total_bytes", totalBytes, 
		"chunks", chunkCount, 
		"duration", time.Since(start))

	return nil
}

// WriteFile writes file content from a stream
func (s *FileService) WriteFile(ctx context.Context, stream *connect.ClientStream[filesv1.WriteFileRequest]) (*connect.Response[filesv1.WriteFileResponse], error) {
	start := time.Now()
	var file afero.File
	var totalBytes int64
	var metadata *filesv1.WriteFileMetadata
	chunkCount := 0

	defer func() {
		if file != nil {
			file.Close()
		}
	}()

	slog.Debug("API: WriteFile stream started")

	for stream.Receive() {
		req := stream.Msg()

		if req.GetMetadata() != nil {
			// First message should contain metadata
			if metadata != nil {
				slog.Error("API: Duplicate metadata in WriteFile stream")
				return nil, connect.NewError(connect.CodeInvalidArgument, errors.New("metadata already received"))
			}
			metadata = req.GetMetadata()
			slog.Debug("API: WriteFile metadata received", "path", metadata.Path, "mode", metadata.Mode, "create_parents", metadata.CreateParents)

			// Create parent directories if requested
			if metadata.CreateParents {
				dir := filepath.Dir(metadata.Path)
				if err := s.storage.MkdirAll(dir, 0755); err != nil {
					slog.Error("API: Failed to create parent directories", "path", metadata.Path, "dir", dir, "error", err)
					return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("failed to create parent directories: %w", err))
				}
				slog.Debug("API: Parent directories created", "path", metadata.Path, "dir", dir)
			}

			// Open/create the file
			var err error
			file, err = s.storage.OpenFile(metadata.Path, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, os.FileMode(metadata.Mode))
			if err != nil {
				slog.Error("API: Failed to create file for writing", "path", metadata.Path, "error", err)
				return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("failed to create file: %w", err))
			}
			slog.Debug("API: File opened for writing", "path", metadata.Path)
		} else if chunk := req.GetChunk(); chunk != nil {
			// Write chunk data
			if file == nil {
				slog.Error("API: Received chunk before metadata in WriteFile stream")
				return nil, connect.NewError(connect.CodeInvalidArgument, errors.New("no metadata received before chunk"))
			}

			n, err := file.Write(chunk.Data)
			if err != nil {
				slog.Error("API: Failed to write chunk", "path", metadata.Path, "chunk", chunkCount, "size", len(chunk.Data), "error", err)
				return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("failed to write chunk: %w", err))
			}
			totalBytes += int64(n)
			chunkCount++
			slog.Debug("API: Chunk written", "path", metadata.Path, "chunk", chunkCount, "size", n, "total_bytes", totalBytes)
		}
	}

	if err := stream.Err(); err != nil {
		slog.Error("API: WriteFile stream error", "error", err)
		return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("stream error: %w", err))
	}

	if metadata == nil {
		slog.Error("API: WriteFile completed without metadata")
		return nil, connect.NewError(connect.CodeInvalidArgument, errors.New("no metadata received"))
	}

	slog.Info("API: File write completed", 
		"path", metadata.Path, 
		"total_bytes", totalBytes, 
		"chunks", chunkCount, 
		"duration", time.Since(start))

	return connect.NewResponse(&filesv1.WriteFileResponse{
		BytesWritten: totalBytes,
	}), nil
}

// CreateDirectory creates a directory
func (s *FileService) CreateDirectory(ctx context.Context, req *connect.Request[filesv1.CreateDirectoryRequest]) (*connect.Response[filesv1.CreateDirectoryResponse], error) {
	start := time.Now()
	slog.Debug("API: CreateDirectory request", "path", req.Msg.Path, "mode", req.Msg.Mode, "create_parents", req.Msg.CreateParents)

	var err error
	if req.Msg.CreateParents {
		err = s.storage.MkdirAll(req.Msg.Path, os.FileMode(req.Msg.Mode))
	} else {
		err = s.storage.Mkdir(req.Msg.Path, os.FileMode(req.Msg.Mode))
	}

	if err != nil {
		slog.Error("API: Failed to create directory", "path", req.Msg.Path, "error", err, "duration", time.Since(start))
		return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("failed to create directory: %w", err))
	}

	slog.Info("API: Directory created successfully", "path", req.Msg.Path, "duration", time.Since(start))
	return connect.NewResponse(&filesv1.CreateDirectoryResponse{}), nil
}

// DeletePath deletes a file or directory
func (s *FileService) DeletePath(ctx context.Context, req *connect.Request[filesv1.DeletePathRequest]) (*connect.Response[filesv1.DeletePathResponse], error) {
	start := time.Now()
	slog.Debug("API: DeletePath request", "path", req.Msg.Path, "recursive", req.Msg.Recursive)

	var err error
	if req.Msg.Recursive {
		err = s.storage.RemoveAll(req.Msg.Path)
	} else {
		err = s.storage.Remove(req.Msg.Path)
	}

	if err != nil {
		slog.Error("API: Failed to delete path", "path", req.Msg.Path, "recursive", req.Msg.Recursive, "error", err, "duration", time.Since(start))
		return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("failed to delete path: %w", err))
	}

	slog.Info("API: Path deleted successfully", "path", req.Msg.Path, "recursive", req.Msg.Recursive, "duration", time.Since(start))
	return connect.NewResponse(&filesv1.DeletePathResponse{}), nil
}

// MovePath moves/renames a file or directory
func (s *FileService) MovePath(ctx context.Context, req *connect.Request[filesv1.MovePathRequest]) (*connect.Response[filesv1.MovePathResponse], error) {
	start := time.Now()
	slog.Debug("API: MovePath request", "from", req.Msg.FromPath, "to", req.Msg.ToPath)

	err := s.storage.Rename(req.Msg.FromPath, req.Msg.ToPath)
	if err != nil {
		slog.Error("API: Failed to move path", "from", req.Msg.FromPath, "to", req.Msg.ToPath, "error", err, "duration", time.Since(start))
		return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("failed to move path: %w", err))
	}

	slog.Info("API: Path moved successfully", "from", req.Msg.FromPath, "to", req.Msg.ToPath, "duration", time.Since(start))
	return connect.NewResponse(&filesv1.MovePathResponse{}), nil
}

// GetPathInfo gets information about a file or directory
func (s *FileService) GetPathInfo(ctx context.Context, req *connect.Request[filesv1.GetPathInfoRequest]) (*connect.Response[filesv1.GetPathInfoResponse], error) {
	start := time.Now()
	slog.Debug("API: GetPathInfo request", "path", req.Msg.Path)

	info, err := s.storage.Stat(req.Msg.Path)
	if err != nil {
		slog.Error("API: Failed to stat path", "path", req.Msg.Path, "error", err, "duration", time.Since(start))
		return nil, connect.NewError(connect.CodeNotFound, fmt.Errorf("failed to stat path: %w", err))
	}

	fileInfo := &filesv1.FileInfo{
		Name:         info.Name(),
		Path:         req.Msg.Path,
		Size:         info.Size(),
		Mode:         uint32(info.Mode()),
		ModifiedTime: timestamppb.New(info.ModTime()),
		IsDir:        info.IsDir(),
	}

	slog.Info("API: Path info retrieved successfully", 
		"path", req.Msg.Path, 
		"size", info.Size(), 
		"is_dir", info.IsDir(), 
		"duration", time.Since(start))

	return connect.NewResponse(&filesv1.GetPathInfoResponse{
		FileInfo: fileInfo,
	}), nil
}

// Ensure FileService implements the interface
var _ filesv1connect.FileServiceHandler = (*FileService)(nil)