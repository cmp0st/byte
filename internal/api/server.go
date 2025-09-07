package api

import (
	"log/slog"
	"net/http"

	"connectrpc.com/connect"
	connectcors "connectrpc.com/cors"
	"connectrpc.com/validate"
	"github.com/cmp0st/byte/gen/files/v1/filesv1connect"
	"github.com/cmp0st/byte/internal/storage"
	"github.com/rs/cors"
)

// Server wraps the HTTP server for the API
type Server struct {
	mux    *http.ServeMux
	server *http.Server
}

// NewServer creates a new API server
func NewServer(storage storage.Interface, addr string) (*Server, error) {
	slog.Debug("API: Creating new server", "addr", addr)

	mux := http.NewServeMux()

	// Create the file service
	fileService := NewFileService(storage)
	slog.Debug("API: File service created")

	validateInterceptor, err := validate.NewInterceptor()
	if err != nil {
		slog.Error("error creating interceptor",
			slog.String("error", err.Error()),
		)
		return nil, err
	}
	// Register the connectRPC handler with CORS for local development
	path, handler := filesv1connect.NewFileServiceHandler(
		fileService,
		connect.WithInterceptors(
			validateInterceptor,
		),
	)

	corsMiddleware := cors.New(cors.Options{
		AllowedOrigins: []string{"http://localhost:8081"},
		AllowedMethods: connectcors.AllowedMethods(),
		AllowedHeaders: connectcors.AllowedHeaders(),
		ExposedHeaders: connectcors.ExposedHeaders(),
	})
	mux.Handle(path, handler)
	slog.Debug("API: ConnectRPC handler registered with CORS", "path", path)

	server := &http.Server{
		Addr:    addr,
		Handler: corsMiddleware.Handler(mux),
	}

	slog.Info("API: Server created successfully", "addr", addr)
	return &Server{
		mux:    mux,
		server: server,
	}, nil
}

// Start starts the HTTP server
func (s *Server) Start() error {
	slog.Info("API: Starting HTTP server", "addr", s.server.Addr)
	err := s.server.ListenAndServe()
	if err != nil {
		slog.Error("API: HTTP server stopped with error", "addr", s.server.Addr, "error", err)
	} else {
		slog.Info("API: HTTP server stopped gracefully", "addr", s.server.Addr)
	}
	return err
}

// Stop stops the HTTP server
func (s *Server) Stop() error {
	slog.Info("API: Stopping HTTP server", "addr", s.server.Addr)
	err := s.server.Close()
	if err != nil {
		slog.Error("API: Failed to stop HTTP server", "addr", s.server.Addr, "error", err)
	} else {
		slog.Info("API: HTTP server stopped successfully", "addr", s.server.Addr)
	}
	return err
}

// GetAddr returns the server address
func (s *Server) GetAddr() string {
	return s.server.Addr
}
