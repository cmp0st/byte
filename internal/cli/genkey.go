package cli

import (
	"crypto/ed25519"
	"crypto/rand"
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

func NewGenKeyCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "genkey",
		Short: "generate ssh host key",
		RunE:  genKey,
	}
}

func genKey(cmd *cobra.Command, args []string) error {
	_, privateKey, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		return fmt.Errorf("failed to generate key: %w", err)
	}

	bytes, err := x509.MarshalPKCS8PrivateKey(privateKey)
	if err != nil {
		return fmt.Errorf("failed to marshal ed25519 key to pkcs8 format: %w", err)
	}

	block := &pem.Block{
		Type:  "PRIVATE KEY",
		Bytes: bytes,
	}

	err = pem.Encode(os.Stdout, block)
	if err != nil {
		return fmt.Errorf("failed to PEM encode private key: %w", err)
	}
	return nil
}
