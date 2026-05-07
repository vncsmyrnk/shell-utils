#!/usr/bin/env bash

# [help]
# Mounts an encrypted container from a file.
#
# Creates a symbolic link to the container at the $HOME dir, if mounted
# successfully

if ! command -v inotifywait >/dev/null 2>&1; then
  exit 1
fi

src="$1"
if [[ -z "$src" ]]; then
  exit 1
fi

dest="$HOME/$(basename "$src" | rev | cut -f2- -d "." | rev)"
if [[ -L "$dest" ]]; then
  echo "destination already exists"
  exit 1
fi

dest_perms=$(stat -c "%a" "$dest" 2>/dev/null)
if [[ -n "$dest_perms" ]] && [[ "$dest_perms" != "0" ]]; then
  echo "destination was not safely unmounted, remove it and try again."
  exit 1
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
rmdir "$dest" 2>/dev/null
mounted_path=$(findmnt -rn -o TARGET "$mapper")
ln -s "$mounted_path" "$dest"
