package main

import (
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"slices"
	"strconv"
	"strings"
	"syscall"

	"shellutils/internal"
	"shellutils/internal/security"

	"golang.org/x/sys/unix"
)

func main() {
	scriptsLookupPaths := []string{internal.ConfigUserScriptsPath, internal.BaseDefaultScriptsPath}

	var (
		path, currentRelativePathArg string
		executableFound              bool
	)

	i := len(os.Args)
	if i <= 1 {
		help()
		return
	}

	for i > 1 {
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
			path, _ = filepath.Abs(matches[0])
			executableFound = true
			break
		}

		i--
	}

	if !executableFound {
		err := catDirectoryEntries(filepath.Join(os.Args[1:]...), scriptsLookupPaths...)
		if err != nil {
			if err == errDirNotFound {
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
		if s, _ := isScript(path); s {
			err := catHelpSection(path)
			if err != nil {
				fatalF(fmt.Sprint(err))
			}
			os.Exit(0)
		}
	}

	if slices.Contains(args, "--to-stdout") {
		if s, _ := isScript(path); !s {
			fatalF("invalid option, the target is not a script.")
		}
		cat(path)
		os.Exit(0)
	}

	verifiedBytes, err := security.VerifyScript(path)
	if err != nil {
		fatalF("security verification failed: %s\n\nmake sure to have properly installed shell-utils and trust user scripts using \033[4mutil config trust\033[0m ", err)
	}

	fd, err := unix.MemfdCreate("util-script", 0)
	if err != nil {
		fatalF("failed to create memfd: %s", err)
	}

	if _, err := unix.Write(fd, verifiedBytes); err != nil {
		fatalF("failed to write to memfd: %s", err)
	}

	scriptFile := os.NewFile(uintptr(fd), "util-script")

	cmd := exec.Command("/proc/self/fd/3", os.Args[i:]...)
	cmd.ExtraFiles = []*os.File{scriptFile}
	cmd.Dir = filepath.Dir(path)

	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	cmd.Env = append(cmd.Environ(),
		fmt.Sprintf("SHELL_UTILS_USER_CONFIG=%s", internal.ConfigUserPath))

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

func help() {
	fmt.Println("util is a shell-agnostic utility tool designed to make your",
		"scripts accessible everywhere using the util command.")
	fmt.Println("It can find and execute your custom scripts like a CLI.")
	fmt.Println("\ne.g. \"$ util folder script\" will look for a script at",
		filepath.Join(internal.ConfigUserScriptsPath, "folder", "script.(*)"))
	fmt.Println("More at https://github.com/vncsmyrnk/shell-utils")
}

func fatalF(s string, args ...any) {
	fmt.Fprintf(os.Stderr, fmt.Sprintln(s), args...)
	os.Exit(1)
}

var errNoHelpAvailable = errors.New("no help available")

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

var errDirNotFound = errors.New("no directory found")

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
	return errDirNotFound
}

func helpSection(p string) (string, error) {
	f, _ := os.ReadFile(p)
	fileContentHelpSectionRegexp := regexp.MustCompile(
		`(?m)^# \[help\]\r?\n((?:^#[^\r\n]*(?:\r?\n|$))*)`)
	matches := fileContentHelpSectionRegexp.FindAllSubmatch(f, -1)
	if len(matches) == 0 {
		return "", errNoHelpAvailable
	}
	fileContentHelpSectionCleanLineRegexp := regexp.MustCompile(`(?m)^# ?`)
	m := matches[0]
	t := fileContentHelpSectionCleanLineRegexp.ReplaceAllString(
		string(m[1]), "")
	return strings.ReplaceAll(t, "\\033", "\033"), nil
}

func pathMatchesForBasePaths(
	relativePath string, basePaths ...string,
) []string {
	for _, p := range basePaths {
		absPath := filepath.Join(p, relativePath)
		if f, err := os.Stat(absPath); err == nil && !f.IsDir() {
			return []string{absPath}
		}
		if m, _ := filepath.Glob(fmt.Sprint(absPath, ".*")); len(m) > 0 {
			return m
		}
	}
	return nil
}

func isScript(filename string) (bool, error) {
	file, err := os.Open(filename)
	if err != nil {
		return false, err
	}
	defer func() {
		if err := file.Close(); err != nil {
			fatalF(err.Error())
		}
	}()

	magic := make([]byte, 2)
	_, err = io.ReadFull(file, magic)
	if err != nil {
		if err == io.EOF || err == io.ErrUnexpectedEOF {
			return false, nil
		}
		return false, err
	}

	return magic[0] == '#' && magic[1] == '!', nil
}
