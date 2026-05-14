package internal

import (
	"os"
	"path/filepath"
)

var (
	BaseDefaultPath        = "."
	BaseDefaultScriptsPath = "./extra"
	ConfigUserPath         = filepath.Join(os.Getenv("HOME"), ".config", "shell-utils")
	ConfigUserScriptsPath  = filepath.Join(ConfigUserPath, "scripts")
)
