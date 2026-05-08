#!/usr/bin/env bash

# [help]
# Unlocks a predefined fscrypt vault and stows it to "$HOME"
#
# The default vault path is $HOME/.vault but it can be overwritten with `-f|--file`.
#
# Sets ssh keys by default.
#
# Usage: util workspaces load <path/to/container>

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
\. "$DIR/_variables"

_ssh_key_add() {
  key=$(
    find ~/.ssh/ -maxdepth 2 \
      -type f -name "id_*" -not -name "*.pub"
  )
  if [[ -z "$key" ]]; then
    echo "ssh key not found" >&2
    return 1
  fi

  ssh-add "$key" || {
    return 1
  }
}

main() {
  vault_path="$_workspaces_vault_path"
  while [[ $# -gt 0 ]]; do
    case $1 in
    -f | --file)
      vault_path="$2"
      shift 2
      ;;
    *)
      break
      ;;
    esac
  done

  fscrypt unlock "$vault_path" || exit 1

  if ! stow -d "$vault_path" -t "$HOME" .; then
    fscrypt lock "$vault_path"
    echo "failed to stow workspace." >&2
    exit 1
  fi

  _ssh_key_add
}

main "$@"
