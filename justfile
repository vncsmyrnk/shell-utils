os := `cat /etc/os-release | grep "^NAME=" | cut -d "=" -f2 | tr -d '"'`

local_bin_path := "$HOME/.local/bin"
local_man_path := "$HOME/.local/share/man/man1"

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
  \. ./setup/vars
  mkdir -p $SU_SCRIPTS_PATH $SU_COMPLETIONS_PATH {{local_bin_path}} {{local_man_path}}
  stow -t {{local_bin_path}} bin
  stow -t $SU_SCRIPTS_PATH defaults --no-folding
  stow -t $SU_SCRIPTS_PATH utils --no-folding
  stow -t $SU_COMPLETIONS_PATH completions
  stow -t $SU_PATH setup
  stow -t {{local_man_path}} man

unset-config:
  #!/bin/sh
  \. ./setup/vars
  stow -D -t {{local_bin_path}} bin
  stow -D -t $SU_SCRIPTS_PATH defaults --no-folding
  stow -D -t $SU_SCRIPTS_PATH utils --no-folding
  stow -D -t $SU_COMPLETIONS_PATH completions
  stow -D -t $SU_PATH setup
  stow -D -t $HOME/.local/share/man/man1 man
