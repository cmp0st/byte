package main

import (
	"log"

	"github.com/cmp0st/byte/internal/cli"
)

func main() {
	if err := cli.New().Execute(); err != nil {
		log.Fatalln(err)
	}
}
