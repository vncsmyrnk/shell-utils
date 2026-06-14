#!/usr/bin/env bash
set -e

# [help]
# Mounts an encrypted container from a file
#
# Usage: util containers mount <container> [mountpoint]

: "${SHELL_UTILS_SCRIPTS_PATH:=}"
# shellcheck source=scripts/_lib.sh
\. "${SHELL_UTILS_SCRIPTS_PATH}/_lib.sh"

: "${SHELL_UTILS_SCRIPT_DIRNAME:=}"

# shellcheck source=scripts/containers.cnt/_lib.sh
\. "${SHELL_UTILS_SCRIPT_DIRNAME}/_lib.sh"

# shellcheck source=scripts/containers.cnt/_variables.sh
\. "${SHELL_UTILS_SCRIPT_DIRNAME}/_variables.sh"

: "${_containers_target_name_prefix:=}"
: "${_containers_image_dir:=}"
: "${_containers_config_dir:=}"

container_ref="$1"
if [[ -f "$container_ref" ]]; then
  src="$1"
  target="$2"
  if [[ -z "$target" ]]; then
    _lib_fatal "source and target are required when specifying an image path."
  fi
else
  src="$_containers_image_dir/$container_ref.img"
  if [[ ! -f "$src" ]]; then
    _lib_fatal "container file not found."
  fi
  if ! config=$(cat "$_containers_config_dir/$1.json" 2>/dev/null); then
    _lib_fatal "container configuration file not found."
  fi
  if ! target=$(jq -cr '.mountpoint' <<<"$config" 2>/dev/null) || [[ "$target" = "null" ]]; then
    _lib_fatal "container mountpoint not defined on the configuration file."
  fi
  target=$(envsubst <<<"$target")
fi

# shellcheck disable=SC2310
if _container_mounted "$src" 2>/dev/null; then
  _lib_fatal "container is already mounted."
fi

target_name=$(
  set -e
  _lib_files_filename_noext "$src"
)
target_name="$_containers_target_name_prefix$target_name"
_container_mount "$src" "$target_name" "$target"
