package key

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/hkdf"
	"crypto/rand"
	"crypto/sha256"
	"errors"
	"fmt"
	"io"
	"time"

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

	// AES 256 key for key encryption (this is used to encrypt new device keys).
	ClientKeyEncryptionKeyDomainSeperator = `client.key-encryption-key.v1`

	// AES 256 key.
	ClientKeyEncryptionKeySize = 32

	// NB: Tokens are minted per-rpc request so we have very short
	// expiration per token to mitigate replay attacks in the case of a
	// token leak.
	DefaultTokenExpiration = 30 * time.Second
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
		return nil, fmt.Errorf("failed to derive client: %w", err)
	}

	tokenKey, err := paseto.V4SymmetricKeyFromBytes(keyseed)
	if err != nil {
		return nil, err
	}

	return &tokenKey, nil
}

func (c ClientChain) Token() (*string, error) {
	now := time.Now()

	token := paseto.NewToken()
	token.SetExpiration(now.Add(DefaultTokenExpiration))
	token.SetIssuedAt(now)
	token.SetNotBefore(now)

	tokenKey, err := c.TokenKey()
	if err != nil {
		return nil, fmt.Errorf("failed to derive client key for token creation: %w", err)
	}

	tokenStr := token.V4Encrypt(*tokenKey, []byte(c.ClientID))

	return &tokenStr, nil
}

func (c ClientChain) EncryptKey(plaintext []byte) ([]byte, error) {
	encKey, err := hkdf.Key(
		sha256.New,
		c.Seed[:],
		nil,
		string(ClientKeyEncryptionKeyDomainSeperator),
		int(ClientKeyEncryptionKeySize),
	)
	if err != nil {
		return nil, err
	}

	block, err := aes.NewCipher(encKey)
	if err != nil {
		return nil, err
	}

	aead, err := cipher.NewGCM(block)
	if err != nil {
		return nil, err
	}

	nonce := make([]byte, aead.NonceSize())

	_, err = io.ReadFull(rand.Reader, nonce)
	if err != nil {
		return nil, err
	}

	ciphertext, err := aead.Seal(nil, nonce, plaintext, nil), nil
	if err != nil {
		return nil, err
	}

	return append(ciphertext, nonce...), nil
}

func (c ClientChain) DecryptKey(ciphertext []byte) ([]byte, error) {
	encKey, err := hkdf.Key(
		sha256.New,
		c.Seed[:],
		nil,
		string(ClientKeyEncryptionKeyDomainSeperator),
		int(ClientKeyEncryptionKeySize),
	)
	if err != nil {
		return nil, err
	}

	block, err := aes.NewCipher(encKey)
	if err != nil {
		return nil, err
	}

	aead, err := cipher.NewGCM(block)
	if err != nil {
		return nil, err
	}

	if len(ciphertext) < aead.NonceSize() {
		return nil, errors.New("invalid ciphertext")
	}

	nonce := ciphertext[len(ciphertext)-aead.NonceSize():]
	rawCiphertext := ciphertext[:len(ciphertext)-aead.NonceSize()]

	plaintext, err := aead.Open(nil, nonce, rawCiphertext, nil)
	if err != nil {
		return nil, err
	}

	return plaintext, nil
}
