package main

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"slices"
	"strconv"
	"strings"
	"syscall"
)

const (
	defaultShell = "sh"
)

var (
	baseDefaultScriptsPath = "./extra"
	validShells            = []string{"bash", "sh", "zsh", "fish"}
)

func main() {
	configUserScriptsPath := filepath.Join(os.Getenv("HOME"), ".config", "shell-utils", "scripts")
	scriptsLookupPaths := []string{baseDefaultScriptsPath, configUserScriptsPath}
	shell, err := shellBin()
	if err != nil {
		fatalF("failed to get shell executable path: %s", err)
	}

	var (
		path, currentRelativePathArg string
		executableFound              bool
	)

	i := len(os.Args)
	if i <= 1 {
		help()
		return
	}

	for {
		if i <= 1 {
			break
		}

		lastCurrentArg := os.Args[i-1]
		_, atoiErr := strconv.Atoi(lastCurrentArg[0:1])
		if lastCurrentArg[0] == '-' || atoiErr == nil {
			i--
			continue
		}

		currentRelativePathArg = filepath.Join(os.Args[1:i]...)
		matches := pathMatchesForBasePaths(currentRelativePathArg, scriptsLookupPaths...)
		if len(matches) > 0 {
			if len(matches) > 1 {
				fatalF("ambiguity detected")
			}
			path = matches[0]
			executableFound = true
			break
		}

		i--
	}

	if !executableFound {
		err := catDirectoryEntries(filepath.Join(os.Args[1:]...), scriptsLookupPaths...)
		if err != nil {
			if err == dirNotFoundErr {
				fatalF("executable not found")
			}
			fatalF("failed to cat directory entries for path: %s", err)
		}
		os.Exit(1)
	}

	args := make([]string, 0, i+1)
	args = append(args, path)
	args = append(args, os.Args[i:]...)

	if slices.Contains(args, "--help") {
		err := catHelpSection(path)
		if err != nil {
			fatalF(fmt.Sprint(err))
		}
		os.Exit(0)
	}

	if slices.Contains(args, "--to-stdout") {
		cat(path)
		os.Exit(0)
	}

	cmd := exec.Command(shell, args...)

	// Connect the command's standard streams directly to the Go program's streams.
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	err = cmd.Run()
	if err != nil {
		var statusCode int
		if exitErr, ok := errors.AsType[*exec.ExitError](err); ok {
			statusCode = exitErr.ExitCode()
		} else {
			statusCode = 1
		}
		os.Exit(statusCode)
	}
}

func shellBin() (string, error) {
	shell := os.Getenv("SHELL")
	if shell == "" {
		shell = defaultShell
	}
	if !slices.Contains(validShells, filepath.Base(shell)) {
		return shell, errors.New("invalid shell")
	}
	return shell, nil
}

func help() {
	fmt.Println("util is a shell-agnostic utility tool designed to make your scripts accessible everywhere using the util command.")
	fmt.Println("It can find and execute your custom scripts like a CLI.")
	fmt.Println("\ne.g. \"$ util folder script\" will look for a script at $SHELL_UTILS_USER_SCRIPTS/folder/script.(*)")
	fmt.Println("More at https://github.com/vncsmyrnk/shell-utils")
}

func fatalF(s string, args ...any) {
	fmt.Fprintf(os.Stderr, fmt.Sprintln(s), args...)
	os.Exit(1)
}

var noHelpAvailableForPath = errors.New("No help available")

func catHelpSection(p string) error {
	s, err := helpSection(p)
	if err != nil {
		return err
	}
	fmt.Print(s)
	return nil
}

func cat(p string) {
	f, _ := os.ReadFile(p)
	fmt.Println(string(f))
}

var dirNotFoundErr = errors.New("no directory found")

func catDirectoryEntries(relativePath string, basePaths ...string) error {
	for _, p := range basePaths {
		dirPath := filepath.Join(p, relativePath)
		entries, err := os.ReadDir(dirPath)
		if err != nil {
			if e, ok := errors.AsType[syscall.Errno](err); ok && e.Is(os.ErrNotExist) {
				continue
			}
			return fmt.Errorf("failed to read entries from non executable dir path: %s", err)
		}
		if len(entries) == 0 {
			continue
		}

		helpFile, err := os.ReadFile(filepath.Join(dirPath, "help"))
		if err != nil {
			if e, ok := errors.AsType[syscall.Errno](err); !ok || !e.Is(os.ErrNotExist) {
				return fmt.Errorf("failed to read help file from non executable dir path: %s", err)
			}
		}
		dirHelpText := "This command has subcommands, but no help section\n"
		if h := string(helpFile); h != "" {
			dirHelpText = h
		}
		fmt.Println(dirHelpText)

		fmt.Println("\033[4mCommands available\033[0m")
		for _, e := range entries {
			dirName := e.Name()
			if strings.HasPrefix(dirName, "_") || dirName == "help" {
				continue
			}
			if e.IsDir() {
				fmt.Println(" ", dirName)
			} else {
				filePath := filepath.Join(dirPath, dirName)
				var helpTitle string
				if hs, err := helpSection(filePath); err == nil {
					helpTitle = fmt.Sprint("- ", strings.Split(hs, "\n")[0])
				}
				noExtFileBaseName := strings.ReplaceAll(filepath.Join(dirName), filepath.Ext(filePath), "")
				fmt.Println(" ", noExtFileBaseName, helpTitle)
			}
		}
		return nil
	}
	return dirNotFoundErr
}

func helpSection(p string) (string, error) {
	f, _ := os.ReadFile(p)
	fileContentHelpSectionRegexp := regexp.MustCompile(
		`(?m)^# \[help\]\r?\n((?:^#[^\r\n]*(?:\r?\n|$))*)`)
	matches := fileContentHelpSectionRegexp.FindAllSubmatch(f, -1)
	if len(matches) == 0 {
		return "", noHelpAvailableForPath
	}
	fileContentHelpSectionCleanLineRegexp := regexp.MustCompile(`(?m)^# ?`)
	m := matches[0]
	t := fileContentHelpSectionCleanLineRegexp.ReplaceAllString(
		string(m[1]), "")
	return strings.ReplaceAll(t, "\\033", "\033"), nil
}

func pathMatchesForBasePaths(relativePath string, basePaths ...string) []string {
	for _, p := range basePaths {
		if matches, _ := filepath.Glob(filepath.Join(p, fmt.Sprint(relativePath, ".*"))); len(matches) > 0 {
			return matches
		}
	}
	return nil
}
