package main

import (
	"os"

	"github.com/cmp0st/byte/internal/cli"
)

func main() {
	err := cli.New().Execute()
	if err != nil {
		os.Exit(1)
	}
}
