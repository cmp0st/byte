package sftp

import (
	"io"
	"log/slog"
	"os"
	"path/filepath"

	"github.com/cmp0st/byte/internal/storage"
	"github.com/pkg/sftp"
	"github.com/spf13/afero"
)

type Server struct {
	fs storage.Interface
}

func NewServer(fs storage.Interface) *Server {
	return &Server{fs: fs}
}

func (s *Server) Fileread(r *sftp.Request) (io.ReaderAt, error) {
	slog.Debug("SFTP file read", "method", "Fileread", "path", r.Filepath)

	file, err := s.fs.Open(r.Filepath)
	if err != nil {
		slog.Error("Failed to open file for reading", "path", r.Filepath, "error", err)
		return nil, sftpErrFromPathError(err)
	}

	slog.Info("File opened for reading", "path", r.Filepath)
	return file, nil
}

func (s *Server) Filewrite(r *sftp.Request) (io.WriterAt, error) {
	slog.Debug("SFTP file write", "method", "Filewrite", "path", r.Filepath, "flags", r.Flags)

	// First try to open the file normally
	file, err := s.fs.OpenFile(r.Filepath, int(r.Flags), 0644)
	if err != nil {
		// If file doesn't exist, try to create parent directories and the file
		if os.IsNotExist(err) {
			slog.Debug("File doesn't exist, creating parent directories", "path", r.Filepath)

			// Extract directory from filepath and create it
			dir := filepath.Dir(r.Filepath)
			if dir != "" && dir != "." && dir != "/" {
				if mkdirErr := s.fs.MkdirAll(dir, 0755); mkdirErr != nil {
					slog.Error("Failed to create parent directories", "dir", dir, "error", mkdirErr)
				} else {
					slog.Debug("Created parent directories", "dir", dir)
				}
			}

			// Try to create/open the file again with create flag
			flags := int(r.Flags) | os.O_CREATE
			file, err = s.fs.OpenFile(r.Filepath, flags, 0644)
			if err != nil {
				slog.Error("Failed to create and open file for writing", "path", r.Filepath, "flags", flags, "error", err)
				return nil, sftpErrFromPathError(err)
			}
			slog.Info("File created and opened for writing", "path", r.Filepath, "flags", flags)
		} else {
			slog.Error("Failed to open file for writing", "path", r.Filepath, "flags", r.Flags, "error", err)
			return nil, sftpErrFromPathError(err)
		}
	} else {
		slog.Info("File opened for writing", "path", r.Filepath, "flags", r.Flags)
	}

	return file, nil
}

func (s *Server) Filecmd(r *sftp.Request) error {
	slog.Debug("SFTP file command", "method", r.Method, "path", r.Filepath, "target", r.Target)

	var err error
	switch r.Method {
	case "Remove":
		err = s.fs.Remove(r.Filepath)
		if err != nil {
			slog.Error("Failed to remove file", "path", r.Filepath, "error", err)
		} else {
			slog.Info("File removed", "path", r.Filepath)
		}
		return sftpErrFromPathError(err)
	case "Mkdir":
		err = s.fs.Mkdir(r.Filepath, 0755)
		if err != nil {
			slog.Error("Failed to create directory", "path", r.Filepath, "error", err)
		} else {
			slog.Info("Directory created", "path", r.Filepath)
		}
		return sftpErrFromPathError(err)
	case "Rmdir":
		err = s.fs.Remove(r.Filepath)
		if err != nil {
			slog.Error("Failed to remove directory", "path", r.Filepath, "error", err)
		} else {
			slog.Info("Directory removed", "path", r.Filepath)
		}
		return sftpErrFromPathError(err)
	case "Rename":
		err = s.fs.Rename(r.Filepath, r.Target)
		if err != nil {
			slog.Error("Failed to rename file", "from", r.Filepath, "to", r.Target, "error", err)
		} else {
			slog.Info("File renamed", "from", r.Filepath, "to", r.Target)
		}
		return sftpErrFromPathError(err)
	case "Setstat":
		slog.Debug("Setstat operation (no-op)", "path", r.Filepath)
		return nil
	default:
		slog.Warn("Unsupported SFTP operation", "method", r.Method, "path", r.Filepath)
		return sftp.ErrSSHFxOpUnsupported
	}
}

func (s *Server) Filelist(r *sftp.Request) (sftp.ListerAt, error) {
	slog.Debug("SFTP file list", "method", r.Method, "path", r.Filepath)

	switch r.Method {
	case "List":
		entries, err := afero.ReadDir(s.fs, r.Filepath)
		if err != nil {
			slog.Error("Failed to list directory", "path", r.Filepath, "error", err)
			return nil, sftpErrFromPathError(err)
		}
		var fileInfos []os.FileInfo
		for _, entry := range entries {
			fileInfos = append(fileInfos, entry)
		}
		slog.Info("Directory listed", "path", r.Filepath, "entries", len(fileInfos))
		return listerat(fileInfos), nil
	case "Stat":
		info, err := s.fs.Stat(r.Filepath)
		if err != nil {
			slog.Error("Failed to stat file", "path", r.Filepath, "error", err)
			return nil, sftpErrFromPathError(err)
		}
		slog.Debug("File stat", "path", r.Filepath, "size", info.Size(), "mode", info.Mode())
		return listerat([]os.FileInfo{info}), nil
	case "Readlink":
		slog.Debug("Readlink operation not supported", "path", r.Filepath)
		return nil, sftp.ErrSSHFxOpUnsupported
	default:
		slog.Warn("Unsupported file list operation", "method", r.Method, "path", r.Filepath)
		return nil, sftp.ErrSSHFxOpUnsupported
	}
}

type listerat []os.FileInfo

func (f listerat) ListAt(ls []os.FileInfo, offset int64) (int, error) {
	if offset >= int64(len(f)) {
		return 0, io.EOF
	}
	n := copy(ls, f[offset:])
	if n < len(ls) {
		return n, io.EOF
	}
	return n, nil
}

func sftpErrFromPathError(err error) error {
	if err == nil {
		return nil
	}
	if os.IsNotExist(err) {
		return sftp.ErrSSHFxNoSuchFile
	}
	if os.IsPermission(err) {
		return sftp.ErrSSHFxPermissionDenied
	}
	return err
}
