package client

import (
	"encoding/base64"
	"log/slog"
	"net/http"

	"connectrpc.com/connect"
	"connectrpc.com/validate"
	"github.com/cmp0st/byte/gen/devices/v1/devicesv1connect"
	"github.com/cmp0st/byte/gen/files/v1/filesv1connect"
	"github.com/cmp0st/byte/internal/auth"
	"github.com/cmp0st/byte/internal/config"
	"github.com/cmp0st/byte/internal/key"
)

type Client struct {
	Files   filesv1connect.FileServiceClient
	Devices devicesv1connect.DeviceServiceClient
}

func New(c config.Client) (*Client, error) {
	rawKey, err := base64.StdEncoding.DecodeString(c.Secret)
	if err != nil {
		return nil, err
	}

	keychain, err := key.NewClientChain(rawKey, c.ID)
	if err != nil {
		return nil, err
	}

	validateInterceptor, err := validate.NewInterceptor()
	if err != nil {
		slog.Error("error creating interceptor",
			slog.String("error", err.Error()),
		)

		return nil, err
	}

	interceptors := connect.WithInterceptors(
		auth.NewClientInterceptor(*keychain),
		validateInterceptor,
	)

	return &Client{
		Files: filesv1connect.NewFileServiceClient(
			http.DefaultClient,
			c.ServerURL,
			connect.WithGRPC(),
			interceptors,
		),
		Devices: devicesv1connect.NewDeviceServiceClient(
			http.DefaultClient,
			c.ServerURL,
			connect.WithGRPC(),
			interceptors,
		),
	}, nil
}
