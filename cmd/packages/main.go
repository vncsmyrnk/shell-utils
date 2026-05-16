package main

import (
	"fmt"
	"os"

	flag "github.com/spf13/pflag"

	"shellutils/internal/packages"
)

func main() {
	helpFlag := flag.BoolP("help", "h", false, "Displays this help message")

	flag.Usage = func() {
		fmt.Fprintln(os.Stderr,
			"Provides actions for managing script packages from GitHub\n",
			"\nUsage:\n", "packages [command] [options] [flags]\n",
			"\nCommands:\n", "sync")
		fmt.Fprintln(os.Stderr, "\nFlags:")
		flag.PrintDefaults()
	}

	flag.Parse()

	if *helpFlag || flag.NArg() == 0 {
		flag.Usage()
		os.Exit(1)
	}

	switch flag.Arg(0) {
	case "sync":
		if err := packages.Sync(); err != nil {
			fmt.Fprintf(os.Stderr, "failed to sync packages: %s\n", err)
			os.Exit(1)
		}
		fmt.Println("Packages synced and trusted successfully.")
	default:
		flag.Usage()
		os.Exit(1)
	}
}
