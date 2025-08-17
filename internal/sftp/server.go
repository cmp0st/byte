package sftp

import (
	"io"
	"os"

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
	file, err := s.fs.Open(r.Filepath)
	if err != nil {
		return nil, sftpErrFromPathError(err)
	}
	return file, nil
}

func (s *Server) Filewrite(r *sftp.Request) (io.WriterAt, error) {
	file, err := s.fs.OpenFile(r.Filepath, int(r.Flags), 0644)
	if err != nil {
		return nil, sftpErrFromPathError(err)
	}
	return file, nil
}

func (s *Server) Filecmd(r *sftp.Request) error {
	switch r.Method {
	case "Remove":
		return sftpErrFromPathError(s.fs.Remove(r.Filepath))
	case "Mkdir":
		return sftpErrFromPathError(s.fs.Mkdir(r.Filepath, 0755))
	case "Rmdir":
		return sftpErrFromPathError(s.fs.Remove(r.Filepath))
	case "Rename":
		return sftpErrFromPathError(s.fs.Rename(r.Filepath, r.Target))
	case "Setstat":
		return nil
	default:
		return sftp.ErrSSHFxOpUnsupported
	}
}

func (s *Server) Filelist(r *sftp.Request) (sftp.ListerAt, error) {
	switch r.Method {
	case "List":
		entries, err := afero.ReadDir(s.fs, r.Filepath)
		if err != nil {
			return nil, sftpErrFromPathError(err)
		}
		var fileInfos []os.FileInfo
		for _, entry := range entries {
			fileInfos = append(fileInfos, entry)
		}
		return listerat(fileInfos), nil
	case "Stat":
		info, err := s.fs.Stat(r.Filepath)
		if err != nil {
			return nil, sftpErrFromPathError(err)
		}
		return listerat([]os.FileInfo{info}), nil
	case "Readlink":
		return nil, sftp.ErrSSHFxOpUnsupported
	default:
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
