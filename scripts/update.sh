#!/usr/bin/env bash
set -e

# [help]
# Updates system packages

main() {
  # shellcheck disable=SC2310
  if exists apt; then sudo apt-get update && sudo apt-get upgrade; fi
  # shellcheck disable=SC2310
  if exists brew; then brew update && brew upgrade; fi
  # shellcheck disable=SC2310
  if exists yay; then yay --devel; fi
}

exists() {
  command -v "$1" >/dev/null
}

main "$@"
