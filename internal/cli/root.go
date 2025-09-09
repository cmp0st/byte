package cli

import (
	"github.com/cmp0st/byte/internal/cli/device"
	"github.com/cmp0st/byte/internal/cli/server"
	"github.com/spf13/cobra"
)

func New() *cobra.Command {
	cmd := &cobra.Command{
		Use:     `byte`,
		Short:   "a new kind of file server",
		Version: "",
	}

	cmd.AddCommand(server.NewCommand())
	cmd.AddCommand(device.NewCommand())
	cmd.AddCommand(newLSCommand())
	cmd.AddCommand(newMkdirCommand())

	return cmd
}
