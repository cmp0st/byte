package server

import (
	"database/sql"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"strconv"

	"github.com/cmp0st/byte/internal/config"
	"github.com/cmp0st/byte/internal/database"
	"github.com/cmp0st/byte/internal/key"
	"github.com/google/uuid"
	qrcode "github.com/skip2/go-qrcode"
	"github.com/spf13/cobra"
)

func newNewDeviceCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "new-device",
		Short: "create new device",
		RunE:  newDevice,
	}
}

type DeviceConfig struct {
	ServerURL string `json:"serverUrl"`
	DeviceID  string `json:"deviceId"`
	Secret    string `json:"secret"`
}

func newDevice(cmd *cobra.Command, args []string) error {
	conf, err := config.LoadServer()
	if err != nil {
		return fmt.Errorf("failed to load config: %w", err)
	}

	if conf.Secret == "" || len(conf.Secret) < 32 {
		return errors.New("invalid server secret, must be more than 32 characters")
	}

	keychain, err := key.NewServerChain([]byte(conf.Secret))
	if err != nil {
		return err
	}

	deviceID, err := uuid.NewRandom()
	if err != nil {
		return err
	}

	var db *database.DB
	{
		sqlitedb, err := sql.Open("sqlite", conf.Database)
		if err != nil {
			return fmt.Errorf("failed to open database: %w", err)
		}

		db = &database.DB{DB: sqlitedb}
	}

	err = db.Migrate()
	if err != nil {
		return err
	}

	err = db.AddDevice(cmd.Context(), deviceID.String())
	if err != nil {
		return err
	}

	deviceKeyChain, err := keychain.ClientChain(deviceID.String())
	if err != nil {
		return err
	}

	// Construct server URL
	serverURL := "http://" + net.JoinHostPort(conf.HTTP.Host, strconv.Itoa(conf.HTTP.Port))

	deviceConfig := DeviceConfig{
		ServerURL: serverURL,
		DeviceID:  deviceID.String(),
		Secret:    base64.StdEncoding.EncodeToString(deviceKeyChain.Seed[:]),
	}

	// Generate QR code
	configJSON, err := json.Marshal(deviceConfig)
	if err != nil {
		return fmt.Errorf("failed to marshal config: %w", err)
	}

	// Use low recovery level for smaller QR code
	qr, err := qrcode.New(string(configJSON), qrcode.Low)
	if err != nil {
		return fmt.Errorf("failed to generate QR code: %w", err)
	}

	fmt.Println("\nDevice created successfully!")
	fmt.Println("Device ID:    ", deviceID.String())
	fmt.Println("Device Secret:", base64.StdEncoding.EncodeToString(deviceKeyChain.Seed[:]))
	fmt.Println("Server URL:   ", serverURL)
	fmt.Println("\nScan this QR code with the Byte iOS app:")
	fmt.Println(qr.ToString(false))

	return nil
}
