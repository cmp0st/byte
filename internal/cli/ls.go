package cli

import (
	"encoding/base64"
	"errors"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"strings"
	"text/tabwriter"
	"time"

	"connectrpc.com/connect"
	filesv1 "github.com/cmp0st/byte/gen/files/v1"
	"github.com/cmp0st/byte/gen/files/v1/filesv1connect"
	"github.com/cmp0st/byte/internal/auth"
	"github.com/cmp0st/byte/internal/config"
	"github.com/cmp0st/byte/internal/key"
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

	rawKey, err := base64.StdEncoding.DecodeString(conf.Secret)
	if err != nil {
		return err
	}

	var keychain key.ClientChain
	keychain.ClientID = conf.ID
	n := copy(keychain.Seed[:], rawKey)
	if n != 32 {
		return errors.New("bad client key")
	}

	client := filesv1connect.NewFileServiceClient(
		http.DefaultClient,
		conf.ServerURL,
		connect.WithInterceptors(
			auth.NewClientInterceptor(keychain),
		),
	)

	var path string
	if len(args) == 0 {
		path = "."
	} else {
		path = args[0]
	}

	resp, err := client.ListDirectory(
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
