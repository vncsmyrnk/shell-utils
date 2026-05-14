#!/usr/bin/env bash

# [help]
# Unmounts an encrypted container
#
# Usage: util containers unmount [CONTAINER]

# shellcheck source=extra/containers/_lib.sh
\. "./_lib.sh"

# shellcheck source=extra/_lib.sh
\. "./../_lib.sh"

# shellcheck source=extra/_error.sh
\. "./../_error.sh"

# shellcheck source=extra/containers/_variables.sh
\. "./_variables.sh"
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
