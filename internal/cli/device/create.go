package device

import (
	"fmt"

	"connectrpc.com/connect"
	devicesv1 "github.com/cmp0st/byte/gen/devices/v1"
	"github.com/cmp0st/byte/internal/client"
	"github.com/cmp0st/byte/internal/config"
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

	fmt.Println(resp)
}
