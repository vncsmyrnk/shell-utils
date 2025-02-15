os := `cat /etc/os-release | grep "^NAME=" | cut -d "=" -f2 | tr -d '"'`

local_bin_path := "$HOME/.local/bin"

install-deps:
  #!/bin/sh
  if [ "{{os}}" = "Debian GNU/Linux" ] || [ "{{os}}" = "Ubuntu" ]; then
    sudo apt-get install stow
  elif [ "{{os}}" = "Arch Linux" ]; then
    sudo pacman -S stow
  fi

install: install-deps config

config:
  #!/bin/sh
  \. ./config/setup
  mkdir -p $UTILS_SCRIPTS_PATH {{local_bin_path}} $UTILS_COMPLETIONS_PATH
  stow -t {{local_bin_path}} bin
  stow -t $UTILS_SCRIPTS_PATH defaults
  stow -t $UTILS_COMPLETIONS_PATH completions
  stow -t $UTILS_PATH config

unset-config:
  #!/bin/sh
  \. ./config/setup
  stow -D -t {{local_bin_path}} bin
  stow -D -t $UTILS_SCRIPTS_PATH defaults
  stow -D -t $UTILS_COMPLETIONS_PATH completions
  stow -D -t $UTILS_PATH config
