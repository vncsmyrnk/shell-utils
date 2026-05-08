#!/usr/bin/env bash

# [help]
# Unstows previously stowed workspace and lock the vault using fscrypt
#
# The default vault path is $HOME/.vault but it can be overwritten with `-f|--file`.
#
# Unsets ssh keys by default.
#
# Usage: util workspaces unload <path/to/container>

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
\. "$DIR/_variables"

LOCK_RETRIES=${LOCK_RETRIES:-10}
LOCK_RETRY_SECONDS=${LOCK_RETRY_SECONDS:-2}

_lock() {
  retries="$1"
  retries=$((retries - 1))
  if [[ "$retries" -eq 0 ]]; then
    return 1
  fi

  result=$(fscrypt lock "$vault_path" 2>&1)
  if [[ "$?" -ne 0 ]]; then
    if grep -q 'incompletely locked' <<<"$result"; then
      sleep "$LOCK_RETRY_SECONDS"
      _lock "$retries"
      return 0
    fi
    if grep -q 'already' <<<"$result" && [[ "$retries" -ne $((LOCK_RETRIES - 1)) ]]; then
      return 0
    fi
    echo "$result"
    return 1
  fi
}

_ssh_key_remove() {
  ssh-add -D || {
    echo "failed to clear ssh entities." >&2
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

  if find "$vault_path" -print0 | xargs -0 fuser >/dev/null 2>&1; then
    echo "there are processes using the vault files." >&2
    exit 1
  fi

  if ! stow -D -d "$vault_path" -t "$HOME" .; then
    echo "failed to unstow workspace." >&2
    exit 1
  fi

  _lock "$LOCK_RETRIES" || exit 1

  _ssh_key_remove
}

main "$@"
