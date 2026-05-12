#!/usr/bin/env bash

# [help]
# Unmounts an encrypted container
#
# Usage: util containers unmount <mountpoint>

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=extra/containers/_lib.sh
\. "$DIR/_lib.sh"

# shellcheck source=extra/containers/_variables.sh
\. "$DIR/_variables.sh"
: "${_containers_target_name_prefix:=}"

src="$1"
if [[ -z "$src" ]]; then
  echo "source and target are required." >&2
  exit 1
fi

if ! target=$(_container_mounted "$src"); then
  echo "$target" >&2
  exit 1
fi

target_name=$(basename "$target" | rev | cut -f2- -d "." | rev)
target_name="$_containers_target_name_prefix$target_name"
_container_unmount "$target_name" "$target"
