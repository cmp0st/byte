package cli

import (
	"fmt"
	"os"

	"connectrpc.com/connect"
	filesv1 "github.com/cmp0st/byte/gen/files/v1"
	"github.com/cmp0st/byte/internal/client"
	"github.com/cmp0st/byte/internal/config"
	"github.com/spf13/cobra"
)

func newMkdirCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:  "mkdir",
		Long: "make directory",
		Run:  mkdir,
		Args: cobra.ExactArgs(1),
	}

	cmd.Flags().BoolP("create-parents", "p", false, "create parent directories")

	return cmd
}

func mkdir(cmd *cobra.Command, args []string) {
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

	parents, err := cmd.Flags().GetBool("create-parents")
	if err != nil {
		fmt.Println("failed to get flag: create-parents")
		os.Exit(1)

		return
	}

	path := args[0]

	_, err = c.MakeDirectory(
		cmd.Context(),
		connect.NewRequest(&filesv1.MakeDirectoryRequest{
			CreateParents: parents,
			Path:          path,
		}),
	)
	if err != nil {
		fmt.Println("failed to make request:", err)

		return
	}

	fmt.Printf("directory %s created\n", path)
}
