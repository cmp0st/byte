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

const (
	// This raw input is user provided configuration.
	ServerRawInputKeyMinimumSize = 32

	// NB: This key isn't actively used for cryptography. Its only used to derive other sub keys.
	ServerRootKeySize            = 32
	ServerRootKeyDomainSeparator = `server.root.v1`

	// Size of Ed25519 private key.
	ServerSSHHostKeySize            = 32
	ServerSSHHostKeyDomainSeparator = `server.ssh.host-key.v1`
)

var (
	ErrInvalidServerRawInputKey = errors.New("invalid server raw input seed")
	ErrServerRootKeyDerivation  = errors.New("failed to derive server root key")
)

type ServerChain struct {
	Seed [ServerRootKeySize]byte
}

func NewServerChain(rawSeed []byte) (*ServerChain, error) {
	if len(rawSeed) < ServerRawInputKeyMinimumSize {
		return nil, ErrInvalidServerRawInputKey
	}

	seed, err := hkdf.Key(
		sha256.New,
		rawSeed,
		nil,
		string(ServerRootKeyDomainSeparator),
		int(ServerRootKeySize),
	)
	if err != nil {
		return nil, ErrServerRootKeyDerivation
	}

	var c ServerChain

	n := copy(c.Seed[:], seed)
	if n != ServerRootKeySize {
		return nil, ErrServerRootKeyDerivation
	}

	return &c, nil
}

func (c ServerChain) ClientChain(clientID string) (*ClientChain, error) {
	clientSeed, err := hkdf.Key(
		sha256.New,
		c.Seed[:],
		nil,
		"client.root.v1."+clientID,
		int(ClientRootKeySize),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to derive ssh host private key: %w", err)
	}

	return NewClientChain(clientSeed, clientID)
}

func (c ServerChain) SSHHostKey() (ed25519.PrivateKey, error) {
	keyseed, err := hkdf.Key(
		sha256.New,
		c.Seed[:],
		nil,
		string(ServerSSHHostKeyDomainSeparator),
		int(ServerSSHHostKeySize),
	)
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
