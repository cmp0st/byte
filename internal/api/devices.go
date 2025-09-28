package api

import (
	"context"
	"log/slog"

	"connectrpc.com/connect"

	devicesv1 "github.com/cmp0st/byte/gen/devices/v1"
	"github.com/cmp0st/byte/gen/devices/v1/devicesv1connect"
	"github.com/cmp0st/byte/internal/auth"
	"github.com/cmp0st/byte/internal/database"
	"github.com/cmp0st/byte/internal/key"
	"github.com/cmp0st/byte/internal/logging"
	"github.com/google/uuid"
)

var _ devicesv1connect.DeviceServiceHandler = &DeviceService{}

// DeviceService implements the files v1 service.
type DeviceService struct {
	DB       *database.DB
	KeyChain key.ServerChain
}

func (ds *DeviceService) CreateDevice(
	ctx context.Context,
	req *connect.Request[devicesv1.CreateDeviceRequest],
) (*connect.Response[devicesv1.CreateDeviceResponse], error) {
	logger := logging.FromContext(ctx)

	id, err := uuid.NewRandom()
	if err != nil {
		logger.Error("failed to create uuid", slog.Any("err", err))

		return nil, connect.NewError(connect.CodeInternal, err)
	}

	err = ds.DB.AddDevice(ctx, id.String())
	if err != nil {
		logger.Error("failed to add device", slog.Any("err", err))

		return nil, connect.NewError(connect.CodeInternal, err)
	}

	// Derive the new device root key
	var newDeviceRootKey []byte
	{
		chain, err := ds.KeyChain.ClientChain(id.String())
		if err != nil {
			logger.Error("failed to derive new device token keychain")

			return nil, connect.NewError(connect.CodeInternal, err)
		}

		newDeviceRootKey = chain.Seed[:]
	}

	var encrypted []byte
	{
		device := auth.DeviceFromContext(ctx)

		chain, err := ds.KeyChain.ClientChain(device)
		if err != nil {
			logger.Error("failed to derive current device keychain")

			return nil, connect.NewError(connect.CodeInternal, err)
		}

		enc, err := chain.EncryptKey(newDeviceRootKey)
		if err != nil {
			logger.Error("failed to encrypt new device key")

			return nil, connect.NewError(connect.CodeInternal, err)
		}

		encrypted = enc
	}

	return connect.NewResponse(&devicesv1.CreateDeviceResponse{
		Id:                 id.String(),
		EncryptedDeviceKey: encrypted,
	}), nil
}

func (ds *DeviceService) ListDevices(
	ctx context.Context,
	req *connect.Request[devicesv1.ListDevicesRequest],
) (*connect.Response[devicesv1.ListDevicesResponse], error) {
	logger := logging.FromContext(ctx)

	ids, err := ds.DB.ListDevices(ctx)
	if err != nil {
		logger.Error("failed to list devices", slog.Any("err", err))

		return nil, connect.NewError(connect.CodeInternal, err)
	}

	devices := make([]*devicesv1.ListDevicesResponse_Device, len(ids))
	for i, id := range ids {
		devices[i] = &devicesv1.ListDevicesResponse_Device{
			Id: id,
		}
	}

	return connect.NewResponse(&devicesv1.ListDevicesResponse{
		Devices: devices,
	}), nil
}

func (ds *DeviceService) DeleteDevice(
	ctx context.Context,
	req *connect.Request[devicesv1.DeleteDeviceRequest],
) (*connect.Response[devicesv1.DeleteDeviceResponse], error) {
	err := ds.DB.DeleteDevice(ctx, req.Msg.GetId())
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}

	return connect.NewResponse(&devicesv1.DeleteDeviceResponse{}), nil
}
