package sftp

import (
	"io"
	"log/slog"
	"os"

	"github.com/cmp0st/byte/internal/storage"
	"github.com/pkg/sftp"
	"github.com/spf13/afero"
)

const (
	DefaultDirectoryPerms = 0o700
	DefaultFilePerms      = 0600
)

type Handlers struct {
	Storage storage.Interface
}

func (s *Handlers) Fileread(r *sftp.Request) (io.ReaderAt, error) {
	slog.Debug("SFTP file read", "method", "Fileread", "path", r.Filepath)

	file, err := s.Storage.Open(r.Filepath)
	if err != nil {
		slog.Error("Failed to open file for reading", "path", r.Filepath, "error", err)
		return nil, sftpErrFromPathError(err)
	}

	slog.Info("File opened for reading", "path", r.Filepath)
	return file, nil
}

func (s *Handlers) Filewrite(r *sftp.Request) (io.WriterAt, error) {
	slog.Debug("SFTP file write", "method", "Filewrite", "path", r.Filepath, "flags", r.Flags)

	var flags int
	pflags := r.Pflags()
	if pflags.Write {
		if pflags.Read {
			flags = os.O_RDWR
		} else {
			flags = os.O_WRONLY
		}
	} else {
		flags = os.O_RDONLY
	}

	if pflags.Creat {
		flags |= os.O_CREATE
	}
	if pflags.Append {
		flags |= os.O_APPEND
	}
	if pflags.Read {
		flags |= os.O_RDONLY
	}
	if pflags.Trunc {
		flags |= os.O_TRUNC
	}
	if pflags.Excl {
		flags |= os.O_EXCL
	}

	// First try to open the file normally
	file, err := s.Storage.OpenFile(r.Filepath, flags, DefaultFilePerms)
	if err != nil {
		slog.Error(
			"Failed to open file for writing",
			"path", r.Filepath,
			"flags", r.Flags,
			"error", err,
		)
		return nil, sftpErrFromPathError(err)
	}
	return file, nil
}

func (s *Handlers) Filecmd(r *sftp.Request) error {
	slog.Debug("SFTP file command", "method", r.Method, "path", r.Filepath, "target", r.Target)

	var err error
	switch r.Method {
	case "Remove":
		err = s.Storage.Remove(r.Filepath)
		if err != nil {
			slog.Error("Failed to remove file", "path", r.Filepath, "error", err)
		} else {
			slog.Info("File removed", "path", r.Filepath)
		}
		return sftpErrFromPathError(err)
	case "Mkdir":
		err = s.Storage.Mkdir(r.Filepath, DefaultDirectoryPerms)
		if err != nil {
			slog.Error("Failed to create directory", "path", r.Filepath, "error", err)
		} else {
			slog.Info("Directory created", "path", r.Filepath)
		}
		return sftpErrFromPathError(err)
	case "Rmdir":
		err = s.Storage.Remove(r.Filepath)
		if err != nil {
			slog.Error("Failed to remove directory", "path", r.Filepath, "error", err)
		} else {
			slog.Info("Directory removed", "path", r.Filepath)
		}
		return sftpErrFromPathError(err)
	case "Rename":
		err = s.Storage.Rename(r.Filepath, r.Target)
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

func (s *Handlers) Filelist(r *sftp.Request) (sftp.ListerAt, error) {
	slog.Debug("SFTP file list", "method", r.Method, "path", r.Filepath)

	switch r.Method {
	case "List":
		entries, err := afero.ReadDir(s.Storage, r.Filepath)
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
		info, err := s.Storage.Stat(r.Filepath)
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
