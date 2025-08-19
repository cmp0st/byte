package api

import (
	"net/http"

	"github.com/cmp0st/byte/gen/files/v1/filesv1connect"
	"github.com/cmp0st/byte/internal/storage"
)

// Server wraps the HTTP server for the API
type Server struct {
	mux    *http.ServeMux
	server *http.Server
}

// NewServer creates a new API server
func NewServer(storage storage.Interface, addr string) *Server {
	mux := http.NewServeMux()

	// Create the file service
	fileService := NewFileService(storage)

	// Register the connectRPC handler
	path, handler := filesv1connect.NewFileServiceHandler(fileService)
	mux.Handle(path, handler)

	server := &http.Server{
		Addr:    addr,
		Handler: mux,
	}

	return &Server{
		mux:    mux,
		server: server,
	}
}

// Start starts the HTTP server
func (s *Server) Start() error {
	return s.server.ListenAndServe()
}

// Stop stops the HTTP server
func (s *Server) Stop() error {
	return s.server.Close()
}

// GetAddr returns the server address
func (s *Server) GetAddr() string {
	return s.server.Addr
}

