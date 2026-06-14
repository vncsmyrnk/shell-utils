package main

//go:generate go run ../../internal/gen_router.go

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"syscall"

	"shellutils/internal"
)

var persistentEnvironmentVariables = []string{
	"HOME", "USER", "EDITOR", "TERM",
	"PAGER", "XDG_RUNTIME_DIR",
	"WAYLAND_DISPLAY", "SSH_AUTH_SOCK",
}

func main() {
	if len(os.Args) < 2 {
		printUsageAndExit()
	}

	if len(os.Args) == 2 && slices.Contains([]string{"--version", "-V"}, os.Args[1]) {
		fmt.Println(internal.Version)
		os.Exit(0)
	}

	scriptsDir := internal.ScriptsPath(internal.DataPath)
	if !strings.HasPrefix(scriptsDir, "/") {
		scriptsDir, _ = os.Getwd()
		scriptsDir = internal.ScriptsPath(scriptsDir)
	}

	if len(os.Args) == 2 && slices.Contains([]string{"--help", "-h"}, os.Args[1]) {
		if err := internal.CatDirectoryEntries(scriptsDir); err != nil {
			log.Fatal(err)
		}
		os.Exit(1)
	}

	env := []string{
		"PATH=/usr/local/bin:/usr/bin:/bin",
		"LANG=C.UTF-8",
	}

	for _, e := range os.Environ() {
		if strings.HasPrefix(e, "SHELL_UTILS_") || pathHasAnyVar(e, persistentEnvironmentVariables) {
			env = append(env, e)
		}
	}

	var routingArgs []string
	for i := 1; i < len(os.Args); i++ {
		arg := os.Args[i]

		if !strings.HasPrefix(arg, "-") {
			routingArgs = os.Args[i:]
			break
		}

		cleanArg := strings.TrimLeft(arg, "-")

		if strings.Contains(cleanArg, "=") {
			parts := strings.SplitN(cleanArg, "=", 2)
			key := formatEnvKey(parts[0])
			val := parts[1]
			env = append(env, fmt.Sprintf("SHELL_UTILS_%s=%s", key, val))
		} else {
			key := formatEnvKey(cleanArg)
			env = append(env, fmt.Sprintf("SHELL_UTILS_%s=1", key))
		}
	}

	if len(routingArgs) == 0 {
		printUsageAndExit()
	}

	var targetPath string
	var scriptArgs []string
	found := false

	for i := len(routingArgs); i > 0; i-- {
		routeKey := strings.Join(routingArgs[:i], ":")

		if path, exists := Router[routeKey]; exists {
			targetPath = path
			scriptArgs = routingArgs[i:]
			found = true
			break
		}
	}

	if !found {
		fmt.Fprintf(os.Stderr, "Error: Unknown command sequence: %s\n", strings.Join(routingArgs, " "))
		os.Exit(1)
	}

	absScriptPath := filepath.Join(scriptsDir, targetPath)
	if f, err := os.Stat(absScriptPath); err == nil && f.IsDir() {
		if err := internal.CatDirectoryEntries(absScriptPath); err != nil {
			log.Fatal(err)
		}
		os.Exit(1)
	}

	for _, arg := range os.Args[1:] {
		if arg == "--" {
			break
		}
		switch arg {
		case "--help", "-h":
			err := internal.CatHelpSection(absScriptPath)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error: Failed to display help section: %s\n", err)
				os.Exit(1)
			}
			os.Exit(0)
		case "--to-stdout", "-o":
			internal.Cat(absScriptPath)
			os.Exit(0)
		}
	}

	env = append(env, fmt.Sprintf("SHELL_UTILS_SCRIPTS_PATH=%s", scriptsDir))
	env = append(env, fmt.Sprintf("SHELL_UTILS_SCRIPT_DIRNAME=%s", filepath.Dir(absScriptPath)))

	execArgv := append([]string{absScriptPath}, scriptArgs...)
	err := syscall.Exec(absScriptPath, execArgv, env)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Execution failed for %s.\n", absScriptPath)
		fmt.Fprintf(os.Stderr, "Ensure the file has executable permissions (chmod +x) and a valid shebang.\n")
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

func formatEnvKey(flagName string) string {
	key := strings.ToUpper(flagName)
	return strings.ReplaceAll(key, "-", "_")
}

func pathHasAnyVar(path string, targets []string) bool {
	for _, t := range targets {
		if strings.HasPrefix(path, fmt.Sprintf("%s=", t)) {
			return true
		}
	}
	return false
}

func printUsageAndExit() {
	fmt.Fprintln(os.Stderr, "Usage: util [global-flags] <command> [subcommands...] [local-flags]")
	fmt.Fprintln(os.Stderr, "\nGlobal flags must use '=' for values (e.g., --config=/path).")
	os.Exit(1)
}
