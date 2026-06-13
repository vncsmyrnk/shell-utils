#!/usr/bin/env bash
set -e

# [help]
# Mounts an encrypted container from a file and stows it on \033[4m$HOME\033[0m
#
# A default workspace can be set on \033[1m$HOME/.shell-utils/workspaces/default.img\033[0m.
#
# Usage: util workspaces set [CONTAINER] [OPTIONS]

: "${SHELL_UTILS_SCRIPTS_PATH:=}"
# shellcheck source=scripts/_lib.sh
\. "${SHELL_UTILS_SCRIPTS_PATH}/_lib.sh"

# shellcheck source=scripts/containers.cnt/_lib.sh
\. "$SHELL_UTILS_SCRIPTS_PATH/containers.cnt/_lib.sh"

: "${SHELL_UTILS_SCRIPT_DIRNAME:=}"
# shellcheck source=scripts/workspaces.ws/_variables.sh
\. "${SHELL_UTILS_SCRIPT_DIRNAME}/_variables.sh"
: "${_workspaces_default_path:=}"

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

_config() {
  : "${_workspaces_config_dir:=}"
  cat "$_workspaces_config_dir/$1.json"
}

main() {
  local src="$1"
  if [[ -z "$src" ]]; then
    if [[ ! -f "$_workspaces_default_path" ]]; then
      _lib_fatal "default workspace not found."
    fi
    src="$_workspaces_default_path"
  fi

  # shellcheck disable=SC2310
  if _container_mounted "$src" >/dev/null 2>&1; then
    _lib_fatal "container is already mounted."
  fi

  : "${_workspaces_mount_path:=}"
  target_name=$(
    set -e
    _lib_files_filename_noext "$src"
  )
  target="$_workspaces_mount_path/$target_name"

  _container_mount "$src" "$target_name" "$target"

  # shellcheck disable=SC2310,SC2311
  if config=$(_config "$target_name" 2>/dev/null) && paths_to_remove=$(jq -cr '.removeBeforeStow[]' <<<"$config" 2>/dev/null); then
    paths=()
    while IFS= read -u 3 -r item; do
      p=$(envsubst <<<"$item")
      if [[ -e "$p" ]]; then
        paths+=("$p")
      fi
    done 3<<<"$paths_to_remove"

    if [[ "${#paths}" -gt 0 ]]; then
      echo "conflicting paths exist:"
      printf -- '- %s\n' "${paths[@]}"
      printf "\nremove paths and procceed? (y/N) "
      read -r answer
      if [[ ! "$answer" =~ ^([Yy])$ ]]; then
        _container_unmount "$target_name" "$target"
        return 1
      fi
      for p in "${paths[@]}"; do
        rm -r "$p"
      done
    fi
  fi

  local stow_target="$HOME"
  if ! stow -d "$target" -t "$stow_target" .; then
    _container_unmount "$target_name" "$target"
    return 1
  fi

  _ssh_key_add
}

main "$@"
