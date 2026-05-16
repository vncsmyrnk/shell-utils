package packages

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"shellutils/internal"
	"shellutils/internal/config"
	"shellutils/internal/security"
	"strings"
	"sync"
)

var (
	ConfigPath = filepath.Join(internal.ConfigUserPath, "config.json")
	LockPath   = filepath.Join(internal.ConfigUserPath, "config.lock")
	CachePath  = filepath.Join(os.Getenv("HOME"), ".cache", "shell-utils", "packages")
)

func LoadConfig() (*config.PackageConfig, error) {
	data, err := os.ReadFile(ConfigPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read config: %w", err)
	}
	var cfg config.PackageConfig
	if err := json.Unmarshal(data, &cfg); err != nil {
		return nil, fmt.Errorf("failed to parse config: %w", err)
	}

	for i, repo := range cfg.Repositories {
		if repo.ScriptsPath == "" && repo.OnUpdateScriptsPath == "" {
			return nil, fmt.Errorf("repository %d (%s) must have at least one of scripts_path or on_update_scripts_path", i, repo.URL)
		}
	}

	return &cfg, nil
}

func LoadLock() (*config.PackageLock, error) {
	data, err := os.ReadFile(LockPath)
	if err != nil {
		if os.IsNotExist(err) {
			return &config.PackageLock{Repositories: make(map[string]string)}, nil
		}
		return nil, err
	}
	var lock config.PackageLock
	if err := json.Unmarshal(data, &lock); err != nil {
		return nil, err
	}
	if lock.Repositories == nil {
		lock.Repositories = make(map[string]string)
	}
	return &lock, nil
}

func SaveLock(lock *config.PackageLock) error {
	data, err := json.MarshalIndent(lock, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(LockPath, data, 0644)
}

func Sync() error {
	cfg, err := LoadConfig()
	if err != nil {
		return err
	}

	lock, err := LoadLock()
	if err != nil {
		return err
	}

	if err := os.MkdirAll(CachePath, 0755); err != nil {
		return fmt.Errorf("failed to create cache directory: %w", err)
	}

	type result struct {
		url    string
		commit string
		err    error
	}
	results := make(chan result, len(cfg.Repositories))
	var wg sync.WaitGroup
	var fsMu sync.Mutex

	for _, repo := range cfg.Repositories {
		wg.Go(func() {
			repoDirName := strings.ReplaceAll(strings.ReplaceAll(repo.URL, "/", "_"), ":", "_")
			repoDir := filepath.Join(CachePath, repoDirName)

			if _, err := os.Stat(repoDir); os.IsNotExist(err) {
				if err := runGit("clone", "--quiet", repo.URL, repoDir); err != nil {
					results <- result{err: fmt.Errorf("failed to clone %s: %w", repo.URL, err)}
					return
				}
			} else {
				if err := runGitInDir(repoDir, "fetch", "--quiet", "origin"); err != nil {
					results <- result{err: fmt.Errorf("failed to fetch %s: %w", repo.URL, err)}
					return
				}
			}

			if err := runGitInDir(repoDir, "checkout", "--quiet", repo.Ref); err != nil {
				results <- result{err: fmt.Errorf("failed to checkout %s to %s: %w", repo.URL, repo.Ref, err)}
				return
			}

			if err := runGitInDir(repoDir, "reset", "--quiet", "--hard", "origin/"+repo.Ref); err != nil {
				log.Printf("failed to reset repository: %v\n", err)
			}

			cmd := exec.Command("git", "rev-parse", "HEAD")
			cmd.Dir = repoDir
			out, err := cmd.Output()
			if err != nil {
				results <- result{err: fmt.Errorf("failed to get commit hash for %s: %w", repo.URL, err)}
				return
			}
			commit := strings.TrimSpace(string(out))

			fsMu.Lock()
			defer fsMu.Unlock()

			prevCommit, isKnown := lock.Repositories[repo.URL]
			needsUpdate := !isKnown || prevCommit != commit

			repoName := getRepoName(repo.URL)

			if repo.ScriptsPath != "" {
				src := filepath.Join(repoDir, repo.ScriptsPath)
				targetName := repo.TargetName
				if targetName == "" {
					targetName = repoName
				}
				dest := filepath.Join(internal.ConfigUserScriptsPath, targetName)
				if err := syncPath(src, dest, needsUpdate); err != nil {
					results <- result{err: fmt.Errorf("failed to sync scripts from %s: %w", repo.URL, err)}
					return
				}
			}

			if repo.OnUpdateScriptsPath != "" {
				src := filepath.Join(repoDir, repo.OnUpdateScriptsPath)
				targetName := repo.OnUpdateTargetName
				if targetName == "" {
					targetName = repoName
				}
				dest := filepath.Join(internal.ConfigUserScriptsPath, "on-update", targetName)
				if err := syncPath(src, dest, needsUpdate); err != nil {
					results <- result{err: fmt.Errorf("failed to sync on-update scripts from %s: %w", repo.URL, err)}
					return
				}
			}

			results <- result{url: repo.URL, commit: commit}
		})
	}

	wg.Wait()
	close(results)

	for res := range results {
		if res.err != nil {
			return res.err
		}
		lock.Repositories[res.url] = res.commit
	}

	if err := SaveLock(lock); err != nil {
		return fmt.Errorf("failed to save lock file: %w", err)
	}

	backend := cfg.Signing.Backend
	if backend == "" && cfg.Signing.UserID != "" {
		backend = "gpg"
	}

	if backend == "gpg" || (backend == "" && len(cfg.Repositories) > 0) {
		fmt.Println("Signing scripts...")
		if err := trust(cfg.Signing.UserID); err != nil {
			return fmt.Errorf("failed to trust scripts: %w", err)
		}
	}

	return nil
}

func getRepoName(url string) string {
	parts := strings.Split(strings.TrimSuffix(url, "/"), "/")
	name := parts[len(parts)-1]
	return strings.TrimSuffix(name, ".git")
}

func runGit(args ...string) error {
	cmd := exec.Command("git", args...)
	return cmd.Run()
}

func runGitInDir(dir string, args ...string) error {
	cmd := exec.Command("git", args...)
	cmd.Dir = dir
	return cmd.Run()
}

func syncPath(src, dest string, needsUpdate bool) error {
	srcInfo, err := os.Stat(src)
	if err != nil {
		return fmt.Errorf("source path %s does not exist: %w", src, err)
	}

	_, err = os.Stat(dest)
	if err == nil {
		if !needsUpdate {
			return nil
		}
		if err := os.RemoveAll(dest); err != nil {
			return fmt.Errorf("failed to remove existing destination %s: %w", dest, err)
		}
	} else if !os.IsNotExist(err) {
		return err
	}

	if srcInfo.IsDir() {
		return copyDir(src, dest)
	}

	// If it's a file, we create a directory for it.
	if err := os.MkdirAll(dest, 0755); err != nil {
		return err
	}
	return copyFile(src, filepath.Join(dest, filepath.Base(src)))
}

func copyFile(src, dest string) error {
	if err := os.MkdirAll(filepath.Dir(dest), 0755); err != nil {
		return err
	}

	source, err := os.Open(src)
	if err != nil {
		return err
	}
	defer func() {
		if err := source.Close(); err != nil {
			log.Fatal(err.Error())
		}
	}()

	destination, err := os.Create(dest)
	if err != nil {
		return err
	}
	defer func() {
		if err := destination.Close(); err != nil {
			log.Fatal(err.Error())
		}
	}()

	if _, err := io.Copy(destination, source); err != nil {
		return err
	}

	info, err := os.Stat(src)
	if err != nil {
		return err
	}
	return os.Chmod(dest, info.Mode())
}

func copyDir(src, dest string) error {
	info, err := os.Stat(src)
	if err != nil {
		return err
	}

	if err := os.MkdirAll(dest, info.Mode()); err != nil {
		return err
	}

	entries, err := os.ReadDir(src)
	if err != nil {
		return err
	}

	for _, entry := range entries {
		srcPath := filepath.Join(src, entry.Name())
		destPath := filepath.Join(dest, entry.Name())
		if entry.IsDir() {
			if err := copyDir(srcPath, destPath); err != nil {
				return err
			}
		} else {
			if err := copyFile(srcPath, destPath); err != nil {
				return err
			}
		}
	}
	return nil
}

func trust(userID string) error {
	backend := &security.GPGBackend{UserID: userID}
	priv, err := security.LoadUserPrivateKeyEncrypted(backend)
	if err != nil {
		return fmt.Errorf("failed to load private key: %w", err)
	}

	return security.SignDirectory(
		internal.ConfigUserScriptsPath,
		priv,
		security.UserManifestPath,
	)
}
