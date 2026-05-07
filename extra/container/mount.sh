#!/usr/bin/env bash

# [help]
# Mounts an encrypted container from a file.
#
# Creates a symbolic link to the container at the $HOME dir, if mounted
# successfully
#
# Usage: util container mount <path/to/container> [-f|--force]

if ! command -v inotifywait >/dev/null 2>&1; then
  exit 1
fi

src=""
force=false
while [[ $# -gt 0 ]]; do
  case $1 in
  -f | --force)
    force=true
    shift
    ;;
  *)
    if [[ -n "$src" ]]; then
      echo "Error: Multiple arguments provided."
      exit 1
    fi
    src="$1"
    shift
    ;;
  esac
done

if [[ -z "$src" ]]; then
  exit 1
fi

dest="$HOME/$(basename "$src" | rev | cut -f2- -d "." | rev)"
if [[ -L "$dest" ]] && [[ "$force" != true ]]; then
  echo "destination already exists"
  exit 1
fi

dest_perms=$(stat -c "%a" "$dest" 2>/dev/null)
if [[ -n "$dest_perms" ]] && [[ "$dest_perms" != "0" ]] && [[ "$force" != true ]]; then
  echo "destination was not safely unmounted, remove it and try again."
  exit 1
fi

if [[ -e "$dest" ]]; then
  rmdir "$dest" || {
    echo "failed to remove dest before creating it."
    exit 1
  }
fi

loop_dev=$(
  udisksctl loop-setup -f "$src" | grep -oP '/dev/loop\d+'
)

block_uuid=$(lsblk -no UUID "$loop_dev" | head -n 1)
mapper="/dev/mapper/luks-$block_uuid"

if [[ ! -b "$mapper" ]]; then
  inotifywait -qq -t 30 -e create "/dev/mapper/"
fi

if [[ ! -b "$mapper" ]]; then
  udisksctl loop-delete -b "$loop_dev"
  exit 1
fi

sleep 1
mounted_path=$(findmnt -rn -o TARGET "$mapper")
ln -s "$mounted_path" "$dest"
