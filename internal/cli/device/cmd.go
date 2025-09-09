package device

import "github.com/spf13/cobra"

func NewCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:  "device",
		Long: "device management commands",
	}

	cmd.AddCommand(newCreateCommand())
	cmd.AddCommand(newListCommand())
	cmd.AddCommand(newDeleteCommand())

	return cmd
}
