package main

import (
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"
)

var (
	baseDefaultScriptsPath = "./extra"
)

func main() {
	if slices.Contains(os.Args, "-h") {
		help()
		os.Exit(0)
	}

	configUserScriptsPath := filepath.Join(os.Getenv("HOME"), ".config", "shell-utils", "scripts")
	pathGlob := fmt.Sprint(filepath.Join(os.Args[1:]...), "*")
	for _, p := range []string{baseDefaultScriptsPath, configUserScriptsPath} {
		path := pathGlob[:len(pathGlob)-1]
		if m, err := filepath.Glob(filepath.Join(p, fmt.Sprint(path, ".*"))); err == nil && len(m) > 0 {
			for _, exactPath := range m {
				fmt.Println(filepath.Rel(p, exactPath))
			}
			return
		}

		if f, err := os.Stat(filepath.Join(p, path)); err == nil && f.IsDir() {
			pathGlob = filepath.Join(path, "*")
		}
		entries, err := filepath.Glob(filepath.Join(p, pathGlob))
		if err != nil {
			fatalF("failed to read dir entries: %s", err)
		}
		for _, e := range entries {
			fileName := filepath.Base(e)
			if strings.HasPrefix(fileName, "_") || fileName == "help" {
				continue
			}
			noExtFileBaseName := strings.ReplaceAll(fileName, filepath.Ext(fileName), "")
			fmt.Println(noExtFileBaseName)
		}
	}
}

func help() {
	fmt.Println("Suggester lists the autocompletion suggestions for the util command's arguments.")
	fmt.Println("\nCheck out \033[4mhttps://github.com/vncsmyrnk/shell-utils\033[0m for more.")
}

func fatalF(s string, args ...any) {
	fmt.Fprintf(os.Stderr, fmt.Sprintln(s), args...)
	os.Exit(1)
}
