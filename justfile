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
  \. ./config/vars
  mkdir -p $SU_SCRIPTS_PATH {{local_bin_path}} $SU_COMPLETIONS_PATH
  stow -t {{local_bin_path}} bin
  stow -t $SU_SCRIPTS_PATH defaults
  stow -t $SU_SCRIPTS_PATH utils --no-folding
  stow -t $SU_COMPLETIONS_PATH completions
  stow -t $SU_PATH config

unset-config:
  #!/bin/sh
  \. ./config/vars
  stow -D -t {{local_bin_path}} bin
  stow -D -t $SU_SCRIPTS_PATH defaults
  stow -D -t $SU_COMPLETIONS_PATH completions
  stow -D -t $SU_SCRIPTS_PATH utils --no-folding
  stow -D -t $SU_PATH config
