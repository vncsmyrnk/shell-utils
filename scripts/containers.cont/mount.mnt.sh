#!/usr/bin/env bash
set -e

# [help]
# Mounts an encrypted container from a file
#
# Usage: util containers mount [CONTAINER] [MOUNTPOINT]

: "${SHELL_UTILS_SCRIPTS_PATH:=}"
# shellcheck source=scripts/_lib.sh
\. "${SHELL_UTILS_SCRIPTS_PATH}/_lib.sh"

: "${SHELL_UTILS_SCRIPT_DIRNAME:=}"

# shellcheck source=scripts/containers.cont/_lib.sh
\. "${SHELL_UTILS_SCRIPT_DIRNAME}/_lib.sh"

# shellcheck source=scripts/containers.cont/_variables.sh
\. "${SHELL_UTILS_SCRIPT_DIRNAME}/_variables.sh"

: "${_containers_target_name_prefix:=}"

src="$1"
target="$2"
if [[ -z "$target" ]]; then
  _lib_fatal "source and target are required."
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
