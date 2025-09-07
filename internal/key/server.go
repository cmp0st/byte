package key

import (
	"bytes"
	"crypto"
	"crypto/ed25519"
	"crypto/hkdf"
	"crypto/sha256"
	"crypto/x509"
	"encoding/pem"
	"errors"
	"fmt"
)

type ServerChain struct {
	Seed [32]byte
}

func NewServerChain(rawSeed []byte) (*ServerChain, error) {
	seed, err := hkdf.Key(sha256.New, rawSeed, nil, "server.root.v1", 32)
	if err != nil {
		return nil, fmt.Errorf("failed to derive ssh host private key: %w", err)
	}

	var c ServerChain
	n := copy(c.Seed[:], seed)
	if n != 32 {
		return nil, errors.New("size of derived seed not 32")
	}
	return &c, nil
}

func (c ServerChain) ClientChain(clientID string) (*ClientChain, error) {
	clientSeed, err := hkdf.Key(sha256.New, c.Seed[:], nil, "client.root.v1."+clientID, 32)
	if err != nil {
		return nil, fmt.Errorf("failed to derive ssh host private key: %w", err)
	}

	var out ClientChain
	n := copy(out.Seed[:], clientSeed)
	if n != 32 {
		return nil, errors.New("size of client derived seed not 32")
	}

	return &out, nil
}

func (c ServerChain) SSHHostKey() (ed25519.PrivateKey, error) {
	keyseed, err := hkdf.Key(sha256.New, c.Seed[:], nil, "server.ssh.host-key.v1", 32)
	if err != nil {
		return nil, fmt.Errorf("failed to derive ssh host private key: %w", err)
	}
	return ed25519.NewKeyFromSeed(keyseed), nil
}

func ToPEM(key crypto.PrivateKey) ([]byte, error) {
	raw, err := x509.MarshalPKCS8PrivateKey(key)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal ed25519 key to pkcs8 format: %w", err)
	}

	block := &pem.Block{
		Type:  "PRIVATE KEY",
		Bytes: raw,
	}

	var buf bytes.Buffer
	err = pem.Encode(&buf, block)
	if err != nil {
		return nil, fmt.Errorf("failed to PEM encode private key: %w", err)
	}
	return buf.Bytes(), nil
}
