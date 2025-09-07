package cli

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"text/tabwriter"
	"time"

	"connectrpc.com/connect"
	filesv1 "github.com/cmp0st/byte/gen/files/v1"
	"github.com/cmp0st/byte/internal/client"
	"github.com/cmp0st/byte/internal/config"
	"github.com/spf13/cobra"
)

func newLSCommand() *cobra.Command {
	return &cobra.Command{
		Use:  "ls",
		Long: "list directory entries",
		RunE: ls,
	}
}

func ls(cmd *cobra.Command, args []string) error {
	conf, err := config.LoadClient()
	if err != nil {
		return err
	}

	c, err := client.New(*conf)
	if err != nil {
		return err
	}

	var path string
	if len(args) == 0 {
		path = "."
	} else {
		path = args[0]
	}

	resp, err := c.ListDirectory(
		cmd.Context(),
		connect.NewRequest(&filesv1.ListDirectoryRequest{
			Path: path,
		}),
	)
	if err != nil {
		return fmt.Errorf("failed to make request: %w", err)
	}

	w := tabwriter.NewWriter(os.Stdout, 0, 0, 1, ' ', 0)
	fmt.Fprintln(w, "Last Modified\tSize\tFile")
	for _, entry := range resp.Msg.Entries {
		mod := entry.ModifiedTime.AsTime().Format(time.RFC3339)
		size := strconv.Itoa(int(entry.Size))
		name := entry.Name
		row := strings.Join([]string{mod, size, name}, "\t")
		fmt.Fprintln(w, row)
	}

	w.Flush()
	return nil
}
