package security

import (
	"crypto/ed25519"
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"os"
	"path/filepath"

	"shellutils/internal"
)

var (
	// GlobalPublicKeyHex is set at build time via ldflags
	GlobalPublicKeyHex string

	UserManifestPath      = filepath.Join(internal.ConfigUserPath, "manifest.json")
	UserPrivateKeyEncPath = filepath.Join(internal.ConfigUserPath, "local.key.enc")
	UserPublicKeyPath     = filepath.Join(internal.ConfigUserPath, "local.pub")
)

func GetGlobalPublicKey() (ed25519.PublicKey, error) {
	if GlobalPublicKeyHex == "" {
		return nil, fmt.Errorf("global public key not set")
	}
	pub, err := hex.DecodeString(GlobalPublicKeyHex)
	if err != nil {
		return nil, fmt.Errorf("invalid global public key hex: %w", err)
	}
	return ed25519.PublicKey(pub), nil
}

func GenerateUserKeypair(backend KeyBackend) (ed25519.PublicKey, error) {
	pub, priv, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		return nil, err
	}

	encryptedPriv, err := backend.Encrypt([]byte(hex.EncodeToString(priv)))
	if err != nil {
		return nil, fmt.Errorf("failed to encrypt private key: %w", err)
	}

	if err := os.MkdirAll(internal.ConfigUserPath, 0700); err != nil {
		return nil, err
	}

	if err := os.WriteFile(UserPrivateKeyEncPath, encryptedPriv, 0600); err != nil {
		return nil, err
	}

	if err := os.WriteFile(UserPublicKeyPath, []byte(hex.EncodeToString(pub)), 0644); err != nil {
		return nil, err
	}

	return pub, nil
}

func LoadUserPrivateKeyEncrypted(backend KeyBackend) (ed25519.PrivateKey, error) {
	data, err := os.ReadFile(UserPrivateKeyEncPath)
	if err != nil {
		return nil, err
	}

	decrypted, err := backend.Decrypt(data)
	if err != nil {
		return nil, fmt.Errorf("failed to decrypt private key: %w", err)
	}
	defer func() {
		// Attempt to clear decrypted memory. 
		// Note: Go GC might move memory, so this is best-effort.
		for i := range decrypted {
			decrypted[i] = 0
		}
	}()

	priv, err := hex.DecodeString(string(decrypted))
	if err != nil {
		return nil, err
	}
	return ed25519.PrivateKey(priv), nil
}

func LoadUserPublicKey() (ed25519.PublicKey, error) {
	data, err := os.ReadFile(UserPublicKeyPath)
	if err != nil {
		return nil, err
	}
	pub, err := hex.DecodeString(string(data))
	if err != nil {
		return nil, err
	}
	return ed25519.PublicKey(pub), nil
}
