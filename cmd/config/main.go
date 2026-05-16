package main

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"syscall"

	flag "github.com/spf13/pflag"

	"shellutils/internal"
	"shellutils/internal/security"
)

func main() {
	helpFlag := flag.BoolP("help", "h", false, "Displays this help message")
	forceFlag := flag.BoolP("force", "f", false, "Performs the action without confirmation")
	gpgUser := flag.String("gpg-user", "", "GPG User ID for encrypting/decrypting the private key")

	flag.Usage = func() {
		fmt.Fprintln(os.Stderr,
			"Provides actions for managing the scripts available to the util command\n",
			"\nUsage:\n", "config [command] [options] [flags]\n",
			"\nCommands:\n", "add\n remove\n trust")
		fmt.Fprintln(os.Stderr, "\nFlags:")
		flag.PrintDefaults()
	}

	addCmd := flag.NewFlagSet("add", flag.ExitOnError)
	addCmd.AddFlagSet(flag.CommandLine)
	addCmd.Usage = func() {
		fmt.Fprint(os.Stderr,
			"Set script to be executed using the `util` command\n\n",
			"Usage:\n", " util config add <path> [flags]\n",
		)
		fmt.Fprint(os.Stderr, "\nFlags:\n", addCmd.FlagUsages())
	}
	targetName := addCmd.StringP("target-name", "t", "", "Name of the file on the target directory.")
	parentPath := addCmd.StringP("parent-path", "p", "", "Parent folder name at the target directory, creating it if not exists.")
	flag.CommandLine.AddFlagSet(addCmd)

	removeCmd := flag.NewFlagSet("remove", flag.ExitOnError)
	removeCmd.AddFlagSet(flag.CommandLine)
	removeCmd.Usage = func() {
		fmt.Fprintln(os.Stderr,
			"Usage:\n", "util config remove <path>",
		)
		fmt.Fprintln(os.Stderr, "\nFlags:")
		flag.PrintDefaults()
	}
	flag.CommandLine.AddFlagSet(removeCmd)

	flag.Parse()
	if flag.NArg() == 0 {
		flag.Usage()
		os.Exit(1)
	}

	switch os.Args[1] {
	case "add":
		if *helpFlag {
			addCmd.Usage()
			os.Exit(1)
		}

		if err := addCmd.Parse(flag.Args()[1:]); err != nil {
			fatalF(err.Error())
		}
		input := addInput{
			srcPath:    addCmd.Arg(0),
			targetName: *targetName,
			parentPath: *parentPath,
			force:      *forceFlag,
		}
		if err := add(input, internal.ConfigUserScriptsPath); err != nil {
			if errors.Is(err, errInsufficientArguments) {
				addCmd.Usage()
				os.Exit(1)
			}
			fmt.Printf("failed to add scripts: %s\n", err)
			os.Exit(1)
		}
		if err := trustUserScripts(*gpgUser); err != nil {
			fmt.Printf("failed to trust user scripts: %s\n", err)
			os.Exit(1)
		}
	case "remove":
		if *helpFlag {
			removeCmd.Usage()
			os.Exit(1)
		}

		if err := removeCmd.Parse(flag.Args()[1:]); err != nil {
			fatalF(err.Error())
		}
		input := removeInput{
			srcPath: removeCmd.Arg(0),
			force:   *forceFlag,
		}
		if err := remove(input, internal.ConfigUserScriptsPath); err != nil {
			if errors.Is(err, errInsufficientArguments) {
				removeCmd.Usage()
				os.Exit(1)
			}
			fmt.Printf("failed to remove scripts: %s\n", err)
			os.Exit(1)
		}
		if err := trustUserScripts(*gpgUser); err != nil {
			fmt.Printf("failed to trust user scripts: %s\n", err)
			os.Exit(1)
		}
	case "trust":
		if err := trustUserScripts(*gpgUser); err != nil {
			fmt.Printf("failed to trust user scripts: %s\n", err)
			os.Exit(1)
		}
		fmt.Println("User scripts trusted and signed successfully.")
	default:
		flag.Usage()
		os.Exit(1)
	}
}

var (
	errInsufficientArguments = errors.New("insufficient arguments")
	errFilePathIsRequired    = fmt.Errorf("a file path is required: %w", errInsufficientArguments)
	errConfirmationFailed    = errors.New("confirmation failed")
)

type addInput struct {
	srcPath    string
	targetName string
	parentPath string
	force      bool
}

func add(a addInput, targetScriptsPath string) error {
	if a.srcPath == "" {
		return errFilePathIsRequired
	}

	src, err := os.Stat(a.srcPath)
	if err != nil {
		if e, ok := errors.AsType[syscall.Errno](err); ok && e.Is(os.ErrNotExist) {
			return errors.New("source path not found")
		}
		return err
	}

	destName := filepath.Base(a.srcPath)
	if a.targetName != "" {
		destName = a.targetName
	}

	destParentDir := a.parentPath
	destPath := filepath.Join(targetScriptsPath, destParentDir, destName)
	f, err := os.Stat(destPath)
	if e, ok := errors.AsType[syscall.Errno](err); ok && !e.Is(os.ErrNotExist) {
		return err
	}
	if err == nil && !f.IsDir() {
		if !a.force && !promptDestructiveConfirmation(
			"There is already a script at this target, it will be overwritten") {
			return errConfirmationFailed
		}
		if err := os.Remove(destPath); err != nil {
			return err
		}
	}

	if _, err := os.Stat(filepath.Dir(destPath)); err != nil {
		if e, ok := errors.AsType[syscall.Errno](err); ok && e.Is(os.ErrNotExist) {
			if err := os.MkdirAll(filepath.Dir(destPath), 0755); err != nil {
				return err
			}
		}
	}

	if src.IsDir() {
		if err := os.Mkdir(destPath, 0755); err != nil {
			if e, ok := errors.AsType[syscall.Errno](err); ok && !e.Is(os.ErrExist) {
				return err
			}
		}
		srcEntries, err := os.ReadDir(a.srcPath)
		if err != nil {
			return err
		}
		for _, e := range srcEntries { // Target dir exists, merges src items into it
			dAbsSrcPath, err := filepath.Abs(filepath.Join(a.srcPath, e.Name()))
			if err != nil {
				return err
			}
			srcPath, err := filepath.Rel(destPath, dAbsSrcPath) // Builds relative path to src just like stow would
			if err != nil {
				return err
			}
			if err := os.Symlink(srcPath, filepath.Join(destPath, e.Name())); err != nil {
				return err
			}
		}
		return nil
	}

	srcPath, err := filepath.Rel(filepath.Dir(destPath), a.srcPath) // Builds relative path to src just like stow would
	if err != nil {
		return err
	}
	return os.Symlink(srcPath, destPath)
}

type removeInput struct {
	srcPath string
	force   bool
}

func remove(r removeInput, targetScriptsPath string) error {
	if r.srcPath == "" {
		return errFilePathIsRequired
	}

	m, _ := filepath.Glob(fmt.Sprint(filepath.Join(targetScriptsPath, r.srcPath), "*"))
	if len(m) > 1 {
		return errors.New("path matches more than one script")
	} else if len(m) == 0 {
		if r.force {
			return nil
		}
		return errors.New("target path not found")
	}

	destPath := m[0]
	f, err := os.Lstat(destPath)
	if err != nil {
		return err
	}

	if f.IsDir() {
		if !r.force && !promptDestructiveConfirmation("Destination is a directory") {
			return errConfirmationFailed
		}
	}

	return os.RemoveAll(destPath)
}

func promptDestructiveConfirmation(msg ...any) bool {
	s := bufio.NewScanner(os.Stdin)
	fmt.Print(msg...)
	fmt.Print(". Continue? [y/N]: ")
	s.Scan()
	input := strings.ToLower(s.Text())

	return strings.ToLower(input) == "y"
}

func fatalF(s string, args ...any) {
	fmt.Fprintf(os.Stderr, fmt.Sprintln(s), args...)
	os.Exit(1)
}

func trustUserScripts(gpgUserID string) error {
	backend := &security.GPGBackend{UserID: gpgUserID}

	priv, err := security.LoadUserPrivateKeyEncrypted(backend)
	if err != nil {
		if os.IsNotExist(err) {
			fmt.Println("No local signing key found. Generating one...")
			_, err = security.GenerateUserKeypair(backend)
			if err != nil {
				return fmt.Errorf("failed to generate local keys: %w", err)
			}
			// Reload the just generated key
			priv, err = security.LoadUserPrivateKeyEncrypted(backend)
			if err != nil {
				return err
			}
		} else {
			return fmt.Errorf("failed to load local private key: %w", err)
		}
	}

	return security.SignDirectory(
		internal.ConfigUserScriptsPath,
		priv,
		security.UserManifestPath,
	)
}
