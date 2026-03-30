package main

import (
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"

	"shellutils/internal"
)

func main() {
	if slices.Contains(os.Args, "-h") {
		help()
		os.Exit(0)
	}

	scriptsLookupPaths := []string{internal.BaseDefaultScriptsPath, internal.ConfigUserScriptsPath}

	validArgs := []string{""}
	if len(os.Args) > 1 {
		validArgs = strings.Split(os.Args[1], " ")
	}

	i := len(validArgs)
	for pathGlob := fmt.Sprint(filepath.Join(validArgs...), "*"); i > 0; pathGlob = fmt.Sprint(filepath.Join(validArgs[:i]...), "*") {
		i--

		for _, p := range scriptsLookupPaths {
			path := pathGlob[:len(pathGlob)-1] // Removes * to search for exact file path matches
			if f, err := os.Stat(filepath.Join(p, path)); err == nil && !f.IsDir() {
				stringArgs := strings.Join(validArgs[i+1:], " ")
				fmt.Print("match;", filepath.Join(p, path), ";", stringArgs, "\n") // Found exact match
				return
			}
			if m, err := filepath.Glob(filepath.Join(p, fmt.Sprint(path, ".*"))); err == nil && len(m) > 0 {
				for _, exactPath := range m {
					stringArgs := strings.Join(validArgs[i+1:], " ")
					if relP, err := filepath.Abs(exactPath); err == nil {
						fmt.Print("match;", relP, ";", stringArgs, "\n") // Found exact matches with extensions
					}
				}
				return
			}

			if f, err := os.Stat(filepath.Join(p, path)); err == nil && f.IsDir() {
				pathGlob = filepath.Join(path, "*") // Its a dir with a trailing space, list all entries inside it
				if validArgs[i] != "" {
					pathGlob = path // A path matching a dir without a trailing whitespace was detected, list only the dir itself
				}
			}
			entries, err := filepath.Glob(filepath.Join(p, pathGlob))
			if err != nil {
				fatalF("failed to read dir entries: %s", err)
			}
			if len(entries) == 0 {
				continue
			}

			i = 0 // Found files or dirs, break out after searching on all base paths
			for _, e := range entries {
				fileName := filepath.Base(e)
				if strings.HasPrefix(fileName, "_") || fileName == "help" {
					continue
				}
				noExtFileBaseName := strings.ReplaceAll(fileName, filepath.Ext(fileName), "")
				fmt.Print("suggest;", noExtFileBaseName, "\n")
			}
		}
	}
}

func help() {
	fmt.Println("Lists autocompletions for util commands arguments and flags.")
	fmt.Println("\nUsage:")
	fmt.Println(" util-complete <query>")
	fmt.Println("\nThe query should be the exact prompt typed on the prompt when <TAB> is preesed.")
	fmt.Println("Check out \033[4mhttps://github.com/vncsmyrnk/shell-utils\033[0m for more.")
}

func fatalF(s string, args ...any) {
	fmt.Fprintf(os.Stderr, fmt.Sprintln(s), args...)
	os.Exit(1)
}
