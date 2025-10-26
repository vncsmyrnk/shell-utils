os := `cat /etc/os-release | grep "^NAME=" | cut -d "=" -f2 | tr -d '"'`

local_bin_path := "$HOME/.local/bin"
local_man_path := "$HOME/.local/share/man/man1"

check-deps:
  #!/bin/bash
  dependencies=(stow grep sh bash sed find)
  missing_dependencies=($(for dep in "${dependencies[@]}"; do command -v "$dep" &> /dev/null || echo "$dep"; done))

  if [ ${#missing_dependencies[@]} -gt 0 ]; then
    echo "Dependencies not found: ${missing_dependencies[*]}"
    echo "Please install them with the appropriate package manager"
    exit 1
  fi

install: check-deps config

config:
  #!/bin/sh
  \. ./setup/vars
  mkdir -p $SU_SCRIPTS_PATH $SU_COMPLETIONS_PATH {{local_bin_path}} {{local_man_path}}
  stow -t {{local_bin_path}} bin
  stow -t $SU_SCRIPTS_PATH defaults --no-folding
  stow -t $SU_SCRIPTS_PATH extra --no-folding
  stow -t $SU_COMPLETIONS_PATH completions
  stow -t $SU_PATH setup
  stow -t {{local_man_path}} man

unset-config:
  #!/bin/sh
  \. ./setup/vars
  stow -D -t {{local_bin_path}} bin
  stow -D -t $SU_SCRIPTS_PATH defaults --no-folding
  stow -D -t $SU_SCRIPTS_PATH extra --no-folding
  stow -D -t $SU_COMPLETIONS_PATH completions
  stow -D -t $SU_PATH setup
  stow -D -t $HOME/.local/share/man/man1 man

shellcheck:
  shellcheck -s sh bin/** defaults/*/**.sh setup/** extra/*/**.sh
