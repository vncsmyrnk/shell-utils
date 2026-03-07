default:
  just --list

install:
  nix profile add

reinstall:
  @rm -rf "$HOME/.cache/shell-utils/scripts"
  nix profile remove shell-utils
  nix profile add

build:
  nix build

run *args:
  @rm -rf "$HOME/.cache/shell-utils/scripts"
  nix run .# {{args}}

shellcheck:
  shellcheck -s sh bin/** defaults/*/**.sh extra/*/**.sh
