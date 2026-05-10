#!/usr/bin/env bash

# [help]
# Unmounts an existent workspace container after its content is unstowed
#
# Usage: util workspaces unset <path/to/container>

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
\. "$DIR/../containers/_lib.sh"
\. "$DIR/_variables.sh"

ssh_key_remove() {
  result=$(ssh-add -D)
  if [[ "$?" -ne 0 ]]; then
    echo "$result" >&2
    return 1
  fi
}

main() {
  src="$1"
  if [[ -z "$src" ]]; then
    exit 1
  fi

  if ! _container_mounted "$src" >/dev/null 2>&1; then
    echo "container is not mounted." >&2
    exit 1
  fi

  target_name=$(basename "$src" | rev | cut -f2- -d "." | rev)
  target="$_workspaces_mount_path/$target_name"

  stow_result=$(
    stow -D -d "$target" -t "$HOME" .
  )
  if [[ "$?" -ne 0 ]]; then
    echo "failed to unstow workspace." >&2
    echo "$stow_result" >&2
    exit 1
  fi

  _container_unmount "$target_name" "$target" || exit 1

  ssh_key_remove
}

main "$@"
