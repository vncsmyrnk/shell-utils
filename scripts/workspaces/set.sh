#!/usr/bin/env bash
set -e

# [help]
# Mounts an encrypted container from a file and stows it on $HOME
#
# A default workspace can be set as `$SHELL_UTILS_WORKSPACES_DEFAULT`.
#
# Usage: util workspaces set [CONTAINER]

: "${SHELL_UTILS_SCRIPTS_PATH:=}"
# shellcheck source=scripts/_lib.sh
\. "${SHELL_UTILS_SCRIPTS_PATH}/_lib.sh"

: "${SHELL_UTILS_SCRIPT_DIRNAME:=}"
# shellcheck source=scripts/containers/_lib.sh
\. "${SHELL_UTILS_SCRIPT_DIRNAME}/_lib.sh"

: "${SHELL_UTILS_SCRIPT_DIRNAME:=}"
# shellcheck source=scripts/workspaces/_variables.sh
\. "${SHELL_UTILS_SCRIPT_DIRNAME}/_variables.sh"

SHELL_UTILS_WORKSPACES_DEFAULT=${SHELL_UTILS_WORKSPACES_DEFAULT:-}

_ssh_key_add() {
  local key
  if ! key=$(
    find ~/.ssh/ -maxdepth 2 \
      -type f -name "id_*" -not -name "*.pub"
  ); then
    echo "ssh key not found" >&2
    return 1
  fi

  ssh-add "$key"
}

main() {
  src="$1"
  if [[ -z "$src" ]]; then
    if [[ ! -f "$SHELL_UTILS_WORKSPACES_DEFAULT" ]]; then
      _lib_fatal "default workspace not found."
    fi
    src="$SHELL_UTILS_WORKSPACES_DEFAULT"
  fi

  # shellcheck disable=SC2310
  if _container_mounted "$src" >/dev/null; then
    _lib_fatal "container is already mounted."
  fi

  : "${_workspaces_mount_path:=}"
  target_name=$(
    set -e
    _lib_files_filename_noext "$src"
  )
  target="$_workspaces_mount_path/$target_name"

  _container_mount "$src" "$target_name" "$target"

  if ! stow -d "$target" -t "$HOME" .; then
    _container_unmount "$target_name" "$target"
    exit 1
  fi

  _ssh_key_add
}

main "$@"
