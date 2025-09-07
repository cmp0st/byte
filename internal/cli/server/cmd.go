package server

import "github.com/spf13/cobra"

func NewCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:  "server",
		Long: "commands related to running a byte server",
	}

	cmd.AddCommand(newRunCommand())
	cmd.AddCommand(newNewDeviceCommand())

	return cmd
}
