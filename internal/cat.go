package internal

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"syscall"
)

func CatDirectoryEntries(dirPath string) error {
	entries, err := os.ReadDir(dirPath)
	if err != nil {
		if e, ok := errors.AsType[syscall.Errno](err); ok && e.Is(os.ErrNotExist) {
			return nil
		}
		return fmt.Errorf("failed to read entries from non executable dir path: %s", err)
	}
	if len(entries) == 0 {
		return fmt.Errorf("no help file found")
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
	fmt.Fprintln(os.Stderr, dirHelpText)

	fmt.Fprintln(os.Stderr, "\033[4mCommands available\033[0m")
	for _, e := range entries {
		dirName := e.Name()
		if strings.HasPrefix(dirName, "_") || dirName == "help" {
			continue
		}
		if e.IsDir() {
			filePath := filepath.Join(dirPath, dirName, "help")
			var helpTitle string
			if _, err := os.Stat(filePath); err == nil {
				c, _ := os.ReadFile(filePath)
				helpTitle = fmt.Sprint("- ", strings.Split(string(c), "\n")[0])
			}
			fmt.Fprintln(os.Stderr, " ", strings.ReplaceAll(dirName, ".", ","), helpTitle)
		} else {
			filePath := filepath.Join(dirPath, dirName)
			var helpTitle string
			if hs, err := helpSection(filePath); err == nil {
				helpTitle = fmt.Sprint("- ", strings.Split(hs, "\n")[0])
			}
			noExtFileBaseName := strings.ReplaceAll(filepath.Join(dirName), filepath.Ext(filePath), "")
			fmt.Fprintln(os.Stderr, " ", strings.ReplaceAll(noExtFileBaseName, ".", ","), helpTitle)
		}
	}
	return nil
}

func CatHelpSection(p string) error {
	s, err := helpSection(p)
	if err != nil {
		return err
	}
	fmt.Fprint(os.Stderr, s)
	return nil
}

func Cat(p string) {
	f, _ := os.ReadFile(p)
	fmt.Println(string(f))
}

func helpSection(p string) (string, error) {
	f, _ := os.ReadFile(p)
	fileContentHelpSectionRegexp := regexp.MustCompile(
		`(?m)^# \[help\]\r?\n((?:^#[^\r\n]*(?:\r?\n|$))*)`)
	matches := fileContentHelpSectionRegexp.FindAllSubmatch(f, -1)
	if len(matches) == 0 {
		return "", fmt.Errorf("no help found")
	}
	fileContentHelpSectionCleanLineRegexp := regexp.MustCompile(`(?m)^# ?`)
	m := matches[0]
	t := fileContentHelpSectionCleanLineRegexp.ReplaceAllString(
		string(m[1]), "")
	return strings.ReplaceAll(t, "\\033", "\033"), nil
}
