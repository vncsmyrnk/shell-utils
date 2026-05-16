package security

import (
	"crypto/ed25519"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"shellutils/internal"
	"sort"
	"strings"
)

type Manifest struct {
	Hashes    map[string]string `json:"hashes"`
	Signature string            `json:"signature"`
}

type KeyBackend interface {
	Encrypt(plaintext []byte) ([]byte, error)
	Decrypt(ciphertext []byte) ([]byte, error)
}

type GPGBackend struct {
	UserID string
}

var _ KeyBackend = &GPGBackend{}

func (g *GPGBackend) Encrypt(plaintext []byte) ([]byte, error) {
	args := []string{"--encrypt", "--armor"}
	if g.UserID != "" {
		args = append(args, "--recipient", g.UserID)
	} else {
		args = append(args, "--default-recipient-self")
	}
	cmd := exec.Command("gpg", args...)
	cmd.Stdin = strings.NewReader(string(plaintext))
	var out strings.Builder
	cmd.Stdout = &out
	if err := cmd.Run(); err != nil {
		return nil, fmt.Errorf("gpg encrypt failed: %w", err)
	}
	return []byte(out.String()), nil
}

func (g *GPGBackend) Decrypt(ciphertext []byte) ([]byte, error) {
	cmd := exec.Command("gpg", "--decrypt", "--quiet")
	cmd.Stdin = strings.NewReader(string(ciphertext))
	var out strings.Builder
	cmd.Stdout = &out
	if err := cmd.Run(); err != nil {
		return nil, fmt.Errorf("gpg decrypt failed: %w", err)
	}
	return []byte(out.String()), nil
}

func CalculateHash(path string) (string, error) {
	f, err := os.Open(path)
	if err != nil {
		return "", err
	}
	defer func() {
		if err := f.Close(); err != nil {
			log.Fatal(err)
		}
	}()

	h := sha256.New()
	if _, err := io.Copy(h, f); err != nil {
		return "", err
	}

	return hex.EncodeToString(h.Sum(nil)), nil
}

func (m *Manifest) CanonicalContent() string {
	var keys []string
	for k := range m.Hashes {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	var sb strings.Builder
	for _, k := range keys {
		sb.WriteString(k)
		sb.WriteString(":")
		sb.WriteString(m.Hashes[k])
		sb.WriteString("\n")
	}
	return sb.String()
}

func (m *Manifest) Sign(privateKey ed25519.PrivateKey) error {
	content := m.CanonicalContent()
	sig := ed25519.Sign(privateKey, []byte(content))
	m.Signature = hex.EncodeToString(sig)
	return nil
}

func (m *Manifest) Verify(publicKey ed25519.PublicKey) error {
	sig, err := hex.DecodeString(m.Signature)
	if err != nil {
		return fmt.Errorf("invalid signature hex: %w", err)
	}

	content := m.CanonicalContent()
	if !ed25519.Verify(publicKey, []byte(content), sig) {
		return fmt.Errorf("signature verification failed")
	}
	return nil
}

func LoadManifest(path string) (*Manifest, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	var m Manifest
	if err := json.Unmarshal(data, &m); err != nil {
		return nil, err
	}
	return &m, nil
}

func (m *Manifest) Save(path string) error {
	data, err := json.MarshalIndent(m, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(path, data, 0644)
}

func SignDirectory(dirPath string, privateKey ed25519.PrivateKey, outputPath string) error {
	m := &Manifest{
		Hashes: make(map[string]string),
	}

	err := filepath.Walk(dirPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() {
			return nil
		}
		if info.Name() == filepath.Base(outputPath) {
			return nil
		}

		hash, err := CalculateHash(path)
		if err != nil {
			return err
		}

		relPath, err := filepath.Rel(dirPath, path)
		if err != nil {
			return err
		}

		m.Hashes[relPath] = hash
		return nil
	})

	if err != nil {
		return err
	}

	if err := m.Sign(privateKey); err != nil {
		return err
	}

	return m.Save(outputPath)
}

func VerifyScript(path string) ([]byte, error) {
	var manifestPath string
	var publicKey ed25519.PublicKey
	var err error
	var isGlobal bool

	absPath, err := filepath.Abs(path)
	if err != nil {
		return nil, err
	}

	if strings.HasPrefix(absPath, internal.BaseDefaultScriptsPath) {
		isGlobal = true
		manifestPath = filepath.Join(internal.BaseDefaultPath, "manifest.json")
		publicKey, err = GetGlobalPublicKey()
		if err != nil {
			return nil, err
		}
	} else if strings.HasPrefix(absPath, internal.ConfigUserScriptsPath) {
		manifestPath = UserManifestPath
		publicKey, err = LoadUserPublicKey()
		if err != nil {
			return nil, err
		}
	} else {
		return nil, fmt.Errorf("script is not in a trusted directory: %s", path)
	}

	m, err := LoadManifest(manifestPath)
	if err != nil {
		return nil, fmt.Errorf("failed to load manifest: %w", err)
	}

	if err := m.Verify(publicKey); err != nil {
		return nil, fmt.Errorf("manifest verification failed: %w", err)
	}

	// Calculate relative path for manifest lookup
	var relPath string
	if isGlobal {
		relPath, _ = filepath.Rel(internal.BaseDefaultScriptsPath, absPath)
	} else {
		relPath, _ = filepath.Rel(internal.ConfigUserScriptsPath, absPath)
	}

	expectedHash, ok := m.Hashes[relPath]
	if !ok {
		return nil, fmt.Errorf("script not found in manifest: %s", relPath)
	}

	scriptBytes, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	h := sha256.New()
	h.Write(scriptBytes)
	actualHash := hex.EncodeToString(h.Sum(nil))

	if actualHash != expectedHash {
		return nil, fmt.Errorf("script hash mismatch for %s", relPath)
	}

	return scriptBytes, nil
}
