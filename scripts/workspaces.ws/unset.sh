#!/usr/bin/env bash

set -e

# [help]
# Unmounts an existent workspace container after its content is unstowed
#
# A default workspace can be set as `$SHELL_UTILS_WORKSPACES_DEFAULT`.
#
# Usage: util workspaces unset [CONTAINER]

: "${SHELL_UTILS_SCRIPTS_PATH:=}"
# shellcheck source=scripts/_lib.sh
\. "${SHELL_UTILS_SCRIPTS_PATH}/_lib.sh"

# shellcheck source=scripts/containers.cnt/_lib.sh
\. "${SHELL_UTILS_SCRIPTS_PATH}/containers.cnt/_lib.sh"

: "${SHELL_UTILS_SCRIPT_DIRNAME:=}"
# shellcheck source=scripts/workspaces.ws/_variables.sh
\. "${SHELL_UTILS_SCRIPT_DIRNAME}/_variables.sh"

SHELL_UTILS_WORKSPACES_DEFAULT=${SHELL_UTILS_WORKSPACES_DEFAULT:-}

force=false
while [[ $# -gt 0 ]]; do
  case $1 in
  -f | --force)
    force=true
    shift
    ;;
  --)
    shift
    break
    ;;
  *)
    break
    ;;
  esac
done

main() {
  src="$1"
  if [[ -z "$src" ]]; then
    if [[ ! -f "$SHELL_UTILS_WORKSPACES_DEFAULT" ]]; then
      _lib_fatal "default workspace not found."
    fi
    src="$SHELL_UTILS_WORKSPACES_DEFAULT"
  fi

  # shellcheck disable=SC2310
  if ! _container_mounted "$src" >/dev/null 2>&1; then
    echo "container is not mounted." >&2
    exit 1
  fi

  # shellcheck disable=SC2310 disable=SC2311
  if ! target_name=$(_lib_files_filename_noext "$src"); then
    _lib_fatal "_lib_files_filename_noext: $target_name"
  fi

  : "${_workspaces_mount_path:=}"
  target="$_workspaces_mount_path/$target_name"

  if fuser -s -m "$target"; then
    if [[ "$force" = false ]]; then
      fuser -v -m "$target"
      read -r -p "kill and procceed? (y/N) " answer
      if [[ ! "$answer" =~ ^([Yy])$ ]]; then
        return 1
      fi
    fi
    fuser -s -m "$target" -k
  fi

  stow -D -d "$target" -t "$HOME" .
  _container_unmount "$target_name" "$target"
  ssh-add -D
}

main "$@"
