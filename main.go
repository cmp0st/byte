package main

import (
	"log/slog"
	"os"

	"github.com/cmp0st/byte/internal/cli"
)

func main() {
	if err := cli.New().Execute(); err != nil {
		slog.Error("Application failed", "error", err)
		os.Exit(1)
	}
}
