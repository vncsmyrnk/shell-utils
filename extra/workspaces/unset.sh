#!/usr/bin/env bash

# [help]
# Unmounts an existent workspace container after its content is unstowed
#
# A default workspace can be set as `$SHELL_UTILS_WORKSPACES_DEFAULT`.
#
# Usage: util workspaces unset <path/to/container>

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=extra/containers/_lib.sh
\. "$DIR/../containers/_lib.sh"

# shellcheck source=extra/containers/_lib.sh
\. "$DIR/_variables.sh"
: "${_workspaces_mount_path:=}"

SHELL_UTILS_WORKSPACES_DEFAULT=${SHELL_UTILS_WORKSPACES_DEFAULT:-}

ssh_key_remove() {
  if ! result=$(ssh-add -D); then
    echo "$result" >&2
    return 1
  fi
}

main() {
  src="$1"
  if [[ -z "$src" ]]; then
    if [[ ! -f "$SHELL_UTILS_WORKSPACES_DEFAULT" ]]; then
      echo "default workspace not found."
      exit 1
    fi
    src="$SHELL_UTILS_WORKSPACES_DEFAULT"
  fi

  if ! _container_mounted "$src" >/dev/null 2>&1; then
    echo "container is not mounted." >&2
    exit 1
  fi

  target_name=$(basename "$src" | rev | cut -f2- -d "." | rev)
  target="$_workspaces_mount_path/$target_name"

  if ! stow_result=$(
    stow -D -d "$target" -t "$HOME" .
  ); then
    echo "failed to unstow workspace." >&2
    echo "$stow_result" >&2
    exit 1
  fi

  _container_unmount "$target_name" "$target" || exit 1

  ssh_key_remove
}

main "$@"
