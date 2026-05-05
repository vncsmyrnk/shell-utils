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

loop_dev=$(
  udisksctl loop-setup -f "$src" | grep -oP '/dev/loop\d+'
)

dest="$HOME/$(basename "$src" | rev | cut -f2- -d "." | rev)"
if [[ -e "$dest" ]]; then
  exit 1
fi

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
