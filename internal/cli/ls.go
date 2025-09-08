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
		Run:  ls,
	}
}

func ls(cmd *cobra.Command, args []string) {
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
		fmt.Println("failed to make request")

		return
	}

	w := tabwriter.NewWriter(os.Stdout, 0, 0, 1, ' ', 0)

	_, err = fmt.Fprintln(w, "Last Modified\tSize\tFile")
	if err != nil {
		fmt.Println("failed to write table header")

		return
	}

	for _, entry := range resp.Msg.GetEntries() {
		mod := entry.GetModifiedTime().AsTime().Format(time.RFC3339)
		size := strconv.Itoa(int(entry.GetSize()))
		name := entry.GetName()
		row := strings.Join([]string{mod, size, name}, "\t")

		_, err = fmt.Fprintln(w, row)
		if err != nil {
			fmt.Println("failed to write table rows")

			return
		}
	}

	err = w.Flush()
	if err != nil {
		fmt.Println("failed to write table")
	}
}
