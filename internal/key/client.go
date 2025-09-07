package key

import (
	"crypto/hkdf"
	"crypto/sha256"
	"errors"
	"fmt"

	"aidanwoods.dev/go-paseto"
)

type ClientChain struct {
	Seed [32]byte

	// ClientID is optionally set if this is a client key chain
	ClientID string
}

func (c ClientChain) TokenKey() (*paseto.V4SymmetricKey, error) {
	if c.ClientID == "" {
		return nil, errors.New("cannot derive client token key for server key chain")
	}

	keyseed, err := hkdf.Key(sha256.New, c.Seed[:], nil, "client.token.paseto-v4.v1", 32)
	if err != nil {
		return nil, fmt.Errorf("failed to derive client ")
	}

	tokenKey, err := paseto.V4SymmetricKeyFromBytes(keyseed)
	if err != nil {
		return nil, err
	}
	return &tokenKey, nil
}
