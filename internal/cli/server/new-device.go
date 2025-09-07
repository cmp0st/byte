package server

import (
	"encoding/base64"
	"fmt"

	"github.com/cmp0st/byte/internal/config"
	"github.com/cmp0st/byte/internal/key"
	"github.com/google/uuid"
	"github.com/spf13/cobra"
)

func newNewDeviceCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "new-device",
		Short: "create new device",
		RunE:  newDevice,
	}
}

func newDevice(cmd *cobra.Command, args []string) error {
	conf, err := config.LoadServer()
	if err != nil {
		return fmt.Errorf("Failed to load config: %v", err)
	}

	if conf.Secret == "" || len(conf.Secret) < 32 {
		return fmt.Errorf("invalid server secret, must be more than 32 charactors")
	}

	keychain, err := key.NewServerChain([]byte(conf.Secret))
	if err != nil {
		return err
	}

	clientID, err := uuid.NewRandom()
	if err != nil {
		return err
	}

	clientKeyChain, err := keychain.ClientChain(clientID.String())
	if err != nil {
		return err
	}

	fmt.Println("client id: ", clientID.String())
	fmt.Println("client secret: ", base64.StdEncoding.EncodeToString(clientKeyChain.Seed[:]))
	return nil
}
