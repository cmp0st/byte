package client

import (
	"encoding/base64"
	"net/http"

	"connectrpc.com/connect"
	"github.com/cmp0st/byte/gen/files/v1/filesv1connect"
	"github.com/cmp0st/byte/internal/auth"
	"github.com/cmp0st/byte/internal/config"
	"github.com/cmp0st/byte/internal/key"
)

func New(c config.Client) (filesv1connect.FileServiceClient, error) {
	rawKey, err := base64.StdEncoding.DecodeString(c.Secret)
	if err != nil {
		return nil, err
	}

	keychain, err := key.NewClientChain(rawKey, c.ID)
	if err != nil {
		return nil, err
	}

	return filesv1connect.NewFileServiceClient(
		http.DefaultClient,
		c.ServerURL,
		connect.WithGRPC(),
		connect.WithInterceptors(
			auth.NewClientInterceptor(*keychain),
		),
	), nil
}
