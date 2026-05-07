#!/usr/bin/env bash

# [help]
# Umnounts a previously mounted container
#
# Unmounts all containers from a directory if a directory is used.
#
# Usage: util container unmount <path/to/container/or/dir/of/containers>

unmount() {
  src="$1"
  dev=$(losetup -n -O NAME -j "$src" | head -n 1)
  mapper=$(lsblk -nlo NAME "$dev" | tail -n 1)

  udisksctl unmount -b "/dev/mapper/$mapper"
  udisksctl lock -b "$dev"

  dest="$HOME/$(basename "$src" | rev | cut -f2- -d "." | rev)"
  rm -rf "$dest"
  mkdir "$dest"
  chmod 000 "$dest" # Avoids the poisoning of the destinatio
}

main() {
  src="$1"
  if [[ -z "$src" ]]; then
    exit 1
  fi

  if [[ -d "$src" ]]; then
    for f in "$src"/*; do
      unmount "$f"
    done
    exit 0
  fi

  unmount "$src"
}

main "$@"
