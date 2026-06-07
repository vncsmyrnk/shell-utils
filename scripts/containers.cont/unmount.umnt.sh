#!/usr/bin/env bash
set -e

# [help]
# Unmounts an encrypted container
#
# Usage: util containers unmount [CONTAINER]

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
if [[ -z "$src" ]]; then
  _lib_fatal "source is required."
fi

target=$(
  set -e
  _container_mounted "$src"
)

target_name=$(
  set -e
  _lib_files_filename_noext "$target"
)

target_name="$_containers_target_name_prefix$target_name"
_container_unmount "$target_name" "$target"
