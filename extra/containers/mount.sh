#!/usr/bin/env bash

# [help]
# Mounts an encrypted container from a file
#
# Usage: util containers mount <path/to/container> <path/to/target>

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=extra/containers/_lib.sh
\. "$DIR/_lib.sh"

# shellcheck source=extra/containers/_variables.sh
\. "$DIR/_variables.sh"
: "${_containers_target_name_prefix:=}"

src="$1"
target="$2"
if [[ -z "$target" ]]; then
  echo "source and target are required." >&2
  exit 1
fi

if _container_mounted "$src" 2>/dev/null; then
  echo "container is already mounted." >&2
  exit 1
fi

target_name=$(basename "$target" | rev | cut -f2- -d "." | rev)
target_name="$_containers_target_name_prefix$target_name"
_container_mount "$src" "$target_name" "$target"
