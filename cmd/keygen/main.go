package main

import (
	"crypto/ed25519"
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"log"
	"os"
	"path/filepath"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: keygen <output-dir>")
		os.Exit(1)
	}
	outputDir := os.Args[1]

	pub, priv, _ := ed25519.GenerateKey(rand.Reader)
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		log.Fatal(err)
	}
	_ = os.WriteFile(filepath.Join(outputDir, "signing.pub"), []byte(hex.EncodeToString(pub)), 0644)
	_ = os.WriteFile(filepath.Join(outputDir, "signing.key"), []byte(hex.EncodeToString(priv)), 0600)
}
