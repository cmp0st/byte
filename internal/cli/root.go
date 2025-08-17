package cli

import (
	"github.com/spf13/cobra"
)

func New() *cobra.Command {
	cmd := &cobra.Command{
		Use:     `byte`,
		Short:   "a new kind of file server",
		Version: "",
	}

	cmd.AddCommand(NewServeCmd())
	cmd.AddCommand(NewGenKeyCmd())

	return cmd
}
