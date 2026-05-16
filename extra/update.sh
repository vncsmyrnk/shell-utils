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
  if [[ -d "$SHELL_UTILS_ON_UPDATE_SCRIPTS_PATH" ]]; then
    printf "\n[UTIL] Now running on-update scripts\n"
    tmp_dir=$(mktemp -d -t shell-utils-updates.XXXXXX)
    trap 'rm -rf "$tmp_dir"' EXIT

    scripts=$(find "$SHELL_UTILS_ON_UPDATE_SCRIPTS_PATH" -type f -print0)
    if [[ -z "$scripts" ]]; then
      echo "no script found." >&2
      exit 1
    fi

    while IFS= read -r -d '' f; do
      echo "Running $f"
      script_path="$tmp_dir/exec_script"

      if ! util-fetch "$f" >"$script_path"; then
        echo "Error: Failed to fetch $f"
        exit 1
      fi

      chmod u+x "$script_path"
      "$script_path"

    done <<<"$scripts"
  fi
}

exists() {
  command -v "$1" >/dev/null
}

main "$@"
