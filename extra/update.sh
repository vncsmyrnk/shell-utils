#!/usr/bin/env bash

# Updates installed apps

# [help]
# Updates system packages and runs custom update scripts.
#
# Runs custom scripts located at \033[1m$SHELL_UTILS_ON_UPDATE_SCRIPTS_PATH\033[0m.

SHELL_UTILS_ON_UPDATE_SCRIPTS_PATH=${SHELL_UTILS_ON_UPDATE_SCRIPTS_PATH:-"$SHELL_UTILS_USER_CONFIG/scripts/on-update"}

main() {
  # Updates package managers
  if exists apt; then sudo apt-get update && sudo apt-get upgrade; fi
  if exists brew; then brew update && brew upgrade; fi
  if exists yay; then yay --devel; fi
  printf "[UTIL] Package managers OK\n"

  # Checks for global update scripts on utils folder
  [[ -x "$SHELL_UTILS_ON_UPDATE_SCRIPTS_PATH" ]] && {
    printf "\n[UTIL] Now updating on-update scripts\n"
    for f in "$SHELL_UTILS_ON_UPDATE_SCRIPTS_PATH"/*; do
      echo "found $f"
      script=$(mktemp)
      if ! util-fetch "$(realpath "$f" || true)" >"$script"; then
        exit 1
      fi
      "$script"
    done
    find "$SHELL_UTILS_ON_UPDATE_SCRIPTS_PATH" \
      -type f \
      -follow \
      -executable \
      -exec echo "found {}." \; \
      -exec {} \;
  }
}

exists() {
  command -v "$1" >/dev/null
}

main "$@"
exit 0
