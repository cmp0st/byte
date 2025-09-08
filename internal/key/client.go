package key

import (
	"crypto/hkdf"
	"crypto/sha256"
	"errors"
	"fmt"

	"aidanwoods.dev/go-paseto"
	"github.com/google/uuid"
)

const (
	// 32 random bytes == 256 bit security.
	ClientRootKeySize = 32

	// 32 bytes -> 256 bit AES key for Paseto v4 symmetic key.
	ClientPasetoTokenKeySize = 32

	// HKDF domain separator for client paseto token key.
	ClientPasetoTokenKeyDomainSeperator = `client.token.paseto-v4.v1`

	// Random UUID.
	ClientIDUUIDVersion = 4
)

var (
	ErrInvalidClientRootKey = errors.New("valid client root key")
	ErrInvalidClientID      = errors.New("invalid client id")
)

type ClientChain struct {
	Seed [ClientRootKeySize]byte

	// ClientID is optionally set if this is a client key chain
	ClientID string
}

func NewClientChain(root []byte, clientID string) (*ClientChain, error) {
	if len(root) != ClientRootKeySize {
		return nil, ErrInvalidClientRootKey
	}

	id, err := uuid.Parse(clientID)
	if err != nil {
		return nil, ErrInvalidClientID
	}

	if id.Version() != ClientIDUUIDVersion {
		return nil, ErrInvalidClientID
	}

	chain := ClientChain{
		ClientID: clientID,
	}

	n := copy(chain.Seed[:], root)
	if n != ClientRootKeySize {
		return nil, fmt.Errorf("failed to copy client root key bytes: %w", ErrInvalidClientRootKey)
	}

	return &chain, nil
}

func (c ClientChain) TokenKey() (*paseto.V4SymmetricKey, error) {
	if c.ClientID == "" {
		return nil, errors.New("cannot derive client token key for server key chain")
	}

	keyseed, err := hkdf.Key(
		sha256.New,
		c.Seed[:],
		nil,
		string(ClientPasetoTokenKeyDomainSeperator),
		int(ClientPasetoTokenKeySize),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to derive client ")
	}

	tokenKey, err := paseto.V4SymmetricKeyFromBytes(keyseed)
	if err != nil {
		return nil, err
	}

	return &tokenKey, nil
}
