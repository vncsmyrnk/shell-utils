#!/usr/bin/env bash

# [help]
# Mounts an encrypted container from a file
#
# Usage: util containers mount [CONTAINER] [MOUNTPOINT]

# shellcheck source=extra/containers/_lib.sh
if ! e=$(util-fetch "$(realpath "./_lib.sh" || true)"); then
  exit 1
fi
\. <(echo "$e")

# shellcheck source=extra/_lib.sh
if ! e=$(util-fetch "$(realpath "./../_lib.sh" || true)"); then
  exit 1
fi
\. <(echo "$e")

# shellcheck source=extra/containers/_variables.sh
if ! e=$(util-fetch "$(realpath "./_variables.sh" || true)"); then
  exit 1
fi
\. <(echo "$e")

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
