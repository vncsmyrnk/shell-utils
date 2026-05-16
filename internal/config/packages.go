package config

type SigningConfig struct {
	Backend string `json:"backend"`
	UserID  string `json:"user_id"`
}

type Repository struct {
	URL                 string `json:"url"`
	Ref                 string `json:"ref"`
	ScriptsPath         string `json:"scripts_path,omitempty"`
	TargetName          string `json:"target_name,omitempty"`
	OnUpdateScriptsPath string `json:"on_update_scripts_path,omitempty"`
	OnUpdateTargetName  string `json:"on_update_target_name,omitempty"`
}

type PackageConfig struct {
	Signing      SigningConfig `json:"signing"`
	Repositories []Repository  `json:"repositories"`
}

type PackageLock struct {
	Repositories map[string]string `json:"repositories"`
}
