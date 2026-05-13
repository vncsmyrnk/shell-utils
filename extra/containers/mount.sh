#!/usr/bin/env bash

# [help]
# Mounts an encrypted container from a file
#
# Usage: util containers mount [CONTAINER] [MOUNTPOINT]

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=extra/containers/_lib.sh
\. "$DIR/_lib.sh"

# shellcheck source=extra/_lib.sh
\. "$DIR/../_lib.sh"

# shellcheck source=extra/containers/_variables.sh
\. "$DIR/_variables.sh"
: "${_containers_target_name_prefix:=}"

src="$1"
target="$2"
if [[ -z "$target" ]]; then
  _lib_fatal "source and target are required."
fi

if _container_mounted "$src" 2>/dev/null; then
  _lib_fatal "container is already mounted."
fi

target_name=$(_lib_files_filename_noext "$src")
target_name="$_containers_target_name_prefix$target_name"
_container_mount "$src" "$target_name" "$target"
