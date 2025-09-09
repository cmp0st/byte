package device

import (
	"fmt"

	"connectrpc.com/connect"
	devicesv1 "github.com/cmp0st/byte/gen/devices/v1"
	"github.com/cmp0st/byte/internal/client"
	"github.com/cmp0st/byte/internal/config"
	"github.com/spf13/cobra"
)

func newDeleteCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:  "delete",
		Long: "delete a device",
		Run:  deletee,
		Args: cobra.ExactArgs(1),
	}

	return cmd
}

func deletee(cmd *cobra.Command, args []string) {
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

	id := args[0]

	resp, err := c.Devices.DeleteDevice(
		cmd.Context(),
		connect.NewRequest(&devicesv1.DeleteDeviceRequest{
			Id: id,
		}),
	)
	if err != nil {
		fmt.Println("failed to delete device:", err)

		return
	}

	fmt.Println(resp)
}
