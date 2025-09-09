package device

import (
	"fmt"

	"connectrpc.com/connect"
	devicesv1 "github.com/cmp0st/byte/gen/devices/v1"
	"github.com/cmp0st/byte/internal/client"
	"github.com/cmp0st/byte/internal/config"
	"github.com/spf13/cobra"
)

func newListCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:  "list",
		Long: "list devices",
		Run:  list,
	}

	return cmd
}

func list(cmd *cobra.Command, args []string) {
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

	resp, err := c.Devices.ListDevices(
		cmd.Context(),
		connect.NewRequest(&devicesv1.ListDevicesRequest{}),
	)
	if err != nil {
		fmt.Println("failed to list devices", err)

		return
	}

	fmt.Println(resp)
}
