package main

import (
	"os"

	"github.com/cmp0st/byte/internal/cli"
)

func main() {
	if err := cli.New().Execute(); err != nil {
		os.Exit(1)
	}
}
