package api

import (
	"log/slog"
	"net/http"
	"time"

	"connectrpc.com/connect"
	"connectrpc.com/validate"
	"github.com/cmp0st/byte/gen/devices/v1/devicesv1connect"
	"github.com/cmp0st/byte/gen/files/v1/filesv1connect"
	"github.com/cmp0st/byte/internal/auth"
	"github.com/cmp0st/byte/internal/database"
	"github.com/cmp0st/byte/internal/key"
	"github.com/cmp0st/byte/internal/logging"
	"github.com/cmp0st/byte/internal/storage"
)

const DefaultReadHeaderTimeout = 10 * time.Second

// Server wraps the HTTP server for the API.
type Server struct {
	mux    *http.ServeMux
	server *http.Server
}

// NewServer creates a new API server.
func NewServer(
	db *database.DB,
	storage storage.Interface,
	chain key.ServerChain,
	logger *slog.Logger,
	addr string,
) (*Server, error) {
	logger.Debug("API: Creating new server", "addr", addr)

	validateInterceptor, err := validate.NewInterceptor()
	if err != nil {
		slog.Error("error creating interceptor",
			slog.String("error", err.Error()),
		)

		return nil, err
	}

	interceptors := connect.WithInterceptors(
		logging.NewInterceptor(logger),
		auth.NewServerInterceptor(chain, db),
		validateInterceptor,
	)

	// Register all services
	mux := http.NewServeMux()
	path, handler := devicesv1connect.NewDeviceServiceHandler(
		&DeviceService{
			DB:       db,
			KeyChain: chain,
		},
		interceptors,
	)
	mux.Handle(path, handler)

	path, handler = filesv1connect.NewFileServiceHandler(
		NewFileService(storage),
		interceptors,
	)
	mux.Handle(path, handler)

	server := &http.Server{
		Addr:              addr,
		Handler:           mux,
		ReadHeaderTimeout: DefaultReadHeaderTimeout,
	}

	slog.Info("API: Server created successfully", "addr", addr)

	return &Server{
		mux:    mux,
		server: server,
	}, nil
}

// Start starts the HTTP server.
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

// Stop stops the HTTP server.
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

// GetAddr returns the server address.
func (s *Server) GetAddr() string {
	return s.server.Addr
}
