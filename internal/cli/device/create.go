package device

import (
	"encoding/base64"
	"encoding/json"
	"fmt"

	"connectrpc.com/connect"
	devicesv1 "github.com/cmp0st/byte/gen/devices/v1"
	"github.com/cmp0st/byte/internal/client"
	"github.com/cmp0st/byte/internal/config"
	"github.com/cmp0st/byte/internal/key"
	qrcode "github.com/skip2/go-qrcode"
	"github.com/spf13/cobra"
)

func newCreateCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:  "create",
		Long: "create new device",
		Run:  create,
	}

	return cmd
}

func create(cmd *cobra.Command, args []string) {
	conf, err := config.LoadClient()
	if err != nil {
		fmt.Println("failed to load client config")

		return
	}

	c, err := client.New(*conf)
	if err != nil {
		fmt.Println("failed to initialize client")

		return
	}

	resp, err := c.Devices.CreateDevice(
		cmd.Context(),
		connect.NewRequest(&devicesv1.CreateDeviceRequest{}),
	)
	if err != nil {
		fmt.Println("failed to create device:", err)

		return
	}

	rawKey, err := base64.StdEncoding.DecodeString(conf.Secret)
	if err != nil {
		fmt.Println("failed to load client secret", err)

		return
	}

	keychain, err := key.NewClientChain(rawKey, conf.ID)
	if err != nil {
		fmt.Println("failed to derive keychain", err)

		return
	}

	plaintext, err := keychain.DecryptKey(resp.Msg.GetEncryptedDeviceKey())
	if err != nil {
		fmt.Println("failed to decrypt device key:", err)

		return
	}

	deviceConfig := map[string]string{
		"serverUrl": conf.ServerURL,
		"deviceId":  resp.Msg.GetId(),
		"secret":    base64.StdEncoding.EncodeToString(plaintext),
	}

	// Generate QR code with low recovery level for smaller size
	configJSON, err := json.Marshal(deviceConfig)
	if err != nil {
		fmt.Println("failed to marshal config:", err)

		return
	}

	qr, err := qrcode.New(string(configJSON), qrcode.Low)
	if err != nil {
		fmt.Println("failed to generate QR code:", err)

		return
	}

	fmt.Println("\nDevice created successfully!")
	fmt.Println("Device ID:    ", resp.Msg.GetId())
	fmt.Println("Device Secret:", base64.StdEncoding.EncodeToString(plaintext))
	fmt.Println("Server URL:   ", conf.ServerURL)
	fmt.Println("\nScan this QR code with the Byte iOS app:")
	fmt.Println(qr.ToString(false))
}
