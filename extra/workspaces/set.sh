#!/usr/bin/env bash

# [help]
# Mounts an encrypted container from a file and stows it on $HOME.
#
# Usage: util workspaces set <path/to/container>

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
\. "$DIR/../containers/_lib.sh"

_ssh_key_add() {
  local key
  key=$(
    find ~/.ssh/ -maxdepth 2 \
      -type f -name "id_*" -not -name "*.pub"
  )
  if [[ -z "$key" ]]; then
    echo "ssh key not found" >&2
    return 1
  fi

  local ssh_result
  ssh_result=$(ssh-add "$key")
  if [[ "$?" -ne 0 ]]; then
    echo "$ssh_result" >&2
    return 1
  fi
}

main() {
  src="$1"
  if [[ -z "$src" ]]; then
    exit 1
  fi

  if _container_mounted "$src" >/dev/null 2>&1; then
    echo "container is already mounted." >&2
    exit 1
  fi

  target_name=$(basename "$src" | rev | cut -f2- -d "." | rev)
  target="/tmp/shell-utils.$(whoami)/$target_name"

  _container_mount "$src" "$target_name" "$target" || exit 1

  stow_result=$(
    stow -d "$target" -t "$HOME" .
  )
  if [[ "$?" -ne 0 ]]; then
    echo "failed to stow workspace." >&2
    echo "$stow_result" >&2
    _container_unmount "$target_name" "$target"
    exit 1
  fi

  ssh_result=$(_ssh_key_add)
  if [[ "$?" -ne 0 ]]; then
    echo "$ssh_result" >&2
  fi
}

main "$@"
