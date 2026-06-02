package internal

import "path/filepath"

var (
	DataPath = "."
)

func ScriptsPath(dataPath string) string {
	return filepath.Join(dataPath, "scripts")
}
