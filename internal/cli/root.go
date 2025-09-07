package cli

import (
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

	return cmd
}
