package main

import (
	"fmt"
	"os"
	"shellutils/internal/security"
	"slices"

	"golang.org/x/sys/unix"
)

func main() {
	if slices.Contains(os.Args, "-h") {
		help()
		os.Exit(0)
	}

	if len(os.Args) <= 1 {
		fatalF("a file path is required.")
	}

	path := os.Args[1]
	content, err := safeScriptContent(path)
	if err != nil {
		fatalF(err.Error())
	}

	fmt.Println(content)
}

func help() {
	fmt.Println("Safely fetches a script content.")
	fmt.Println("\nUsage:")
	fmt.Println(" util-fetch [FILE]")
	fmt.Println("Check out \033[4mhttps://github.com/vncsmyrnk/shell-utils\033[0m for more.")
}

func fatalF(s string, args ...any) {
	fmt.Fprintf(os.Stderr, fmt.Sprintln(s), args...)
	os.Exit(1)
}

func safeScriptContent(path string) (string, error) {
	verifiedBytes, err := security.VerifyScript(path)
	if err != nil {
		return "", fmt.Errorf("security verification failed: %w", err)
	}

	fd, err := unix.MemfdCreate("util-script", 0)
	if err != nil {
		return "", fmt.Errorf("failed to create memfd: %w", err)
	}

	if _, err := unix.Write(fd, verifiedBytes); err != nil {
		return "", fmt.Errorf("failed to write to memfd: %w", err)
	}

	return string(verifiedBytes), nil
}
