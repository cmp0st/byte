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
	Logger  *slog.Logger
}

func (s *Handlers) Fileread(r *sftp.Request) (io.ReaderAt, error) {
	logger := s.Logger.With(
		slog.String("path", r.Filepath),
		slog.String("method", r.Method),
		slog.String("target", r.Target),
		slog.Any("attrs", r.Attrs),
		slog.Any("flags", r.Flags),
	)
	logger.Debug("sftp file read", "method", "Fileread")

	file, err := s.Storage.Open(r.Filepath)
	if err != nil {
		logger.Error("failed to open file for reading", slog.Any("err", err))

		return nil, sftpErrFromPathError(err)
	}

	logger.Info("file opened for reading")

	return file, nil
}

func (s *Handlers) Filewrite(r *sftp.Request) (io.WriterAt, error) {
	logger := s.Logger.With(
		slog.String("path", r.Filepath),
		slog.String("method", r.Method),
		slog.String("target", r.Target),
		slog.Any("attrs", r.Attrs),
		slog.Any("flags", r.Flags),
	)
	logger.Debug("sftp file write")

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
		logger.Error(
			"failed to open file for writing",
			"error", err,
		)

		return nil, sftpErrFromPathError(err)
	}

	return file, nil
}

func (s *Handlers) Filecmd(r *sftp.Request) error {
	logger := s.Logger.With(
		slog.String("path", r.Filepath),
		slog.String("method", r.Method),
		slog.String("target", r.Target),
		slog.Any("attrs", r.Attrs),
		slog.Any("flags", r.Flags),
	)
	logger.Debug("sftp file command")

	var err error

	switch r.Method {
	case "Remove":
		err = s.Storage.Remove(r.Filepath)
		if err != nil {
			logger.Error(
				"failed to remove file",
				slog.Any("err", err),
			)
		} else {
			logger.Info("file removed")
		}

		return sftpErrFromPathError(err)
	case "Mkdir":
		err = s.Storage.Mkdir(r.Filepath, DefaultDirectoryPerms)
		if err != nil {
			logger.Error(
				"failed to create directory",
				slog.Any("err", err),
			)
		} else {
			logger.Info("directory created")
		}

		return sftpErrFromPathError(err)
	case "Rmdir":
		err = s.Storage.Remove(r.Filepath)
		if err != nil {
			logger.Error("Failed to remove directory", "err", err)
		} else {
			logger.Info("Directory removed")
		}

		return sftpErrFromPathError(err)
	case "Rename":
		err = s.Storage.Rename(r.Filepath, r.Target)
		if err != nil {
			logger.Error("failed to rename file", "err", err)
		} else {
			logger.Info("File renamed")
		}

		return sftpErrFromPathError(err)
	case "Setstat":
		logger.Debug("Setstat operation (no-op)")

		return nil
	default:
		logger.Warn("Unsupported SFTP operation")

		return sftp.ErrSSHFxOpUnsupported
	}
}

func (s *Handlers) Filelist(r *sftp.Request) (sftp.ListerAt, error) {
	logger := s.Logger.With(
		slog.String("path", r.Filepath),
		slog.String("method", r.Method),
		slog.String("target", r.Target),
		slog.Any("attrs", r.Attrs),
		slog.Any("flags", r.Flags),
	)
	logger.Debug("sftp file list")

	switch r.Method {
	case "List":
		entries, err := afero.ReadDir(s.Storage, r.Filepath)
		if err != nil {
			logger.Error("failed to list directory", slog.Any("err", err))

			return nil, sftpErrFromPathError(err)
		}

		logger.Info(
			"directory listed",
			slog.Int("entries", len(entries)),
		)

		return listerat(entries), nil

	case "Stat":
		info, err := s.Storage.Stat(r.Filepath)
		if err != nil {
			logger.Error("failed to stat file", "err", err)

			return nil, sftpErrFromPathError(err)
		}

		logger.Debug(
			"file stat",
			slog.Int64("size", info.Size()),
			slog.Any("mode", info.Mode()),
			slog.Time("modified_time", info.ModTime()),
		)

		return listerat([]os.FileInfo{info}), nil
	case "Readlink":
		logger.Error("readlink operation not supported")

		return nil, sftp.ErrSSHFxOpUnsupported
	default:
		logger.Warn("Unsupported file list operation")

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
