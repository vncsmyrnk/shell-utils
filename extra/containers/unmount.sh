#!/usr/bin/env bash

# [help]
# Unmounts an encrypted container
#
# Usage: util containers unmount <mountpoint>

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
\. "$DIR/_lib.sh"

src="$1"
if [[ -z "$src" ]]; then
  echo "source and target are required." >&2
  exit 1
fi

target=$(_container_mounted "$src")
if [[ "$?" -ne 0 ]]; then
  echo "$target" >&2
  exit 1
fi

target_name=$(basename "$target" | rev | cut -f2- -d "." | rev)
_container_unmount "$target_name" "$target"
