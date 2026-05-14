package main

import (
	"crypto/ed25519"
	"encoding/hex"
	"fmt"
	"os"
	"path/filepath"
	"shellutils/internal/security"
)

func main() {
	if len(os.Args) < 4 {
		fmt.Println("Usage: manifestgen <scripts-dir> <priv-key-hex> <output-dir>")
		os.Exit(1)
	}

	scriptsDir := os.Args[1]
	privKeyHex := os.Args[2]
	outputDir := os.Args[3]

	privKeyBytes, err := hex.DecodeString(privKeyHex)
	if err != nil {
		fmt.Printf("invalid private key hex: %s\n", err)
		os.Exit(1)
	}
	privKey := ed25519.PrivateKey(privKeyBytes)

	m := &security.Manifest{Hashes: make(map[string]string)}
	err = filepath.Walk(scriptsDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() || info.Name() == "manifest.json" {
			return nil
		}
		rel, err := filepath.Rel(scriptsDir, path)
		if err != nil {
			return err
		}
		hash, err := security.CalculateHash(path)
		if err != nil {
			return err
		}
		m.Hashes[rel] = hash
		return nil
	})
	if err != nil {
		fmt.Printf("failed to walk scripts: %s\n", err)
		os.Exit(1)
	}

	if err := m.Sign(privKey); err != nil {
		fmt.Printf("failed to sign manifest: %s\n", err)
		os.Exit(1)
	}

	if err := m.Save(filepath.Join(outputDir, "manifest.json")); err != nil {
		fmt.Printf("failed to save manifest: %s\n", err)
		os.Exit(1)
	}
}
