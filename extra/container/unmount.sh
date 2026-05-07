#!/usr/bin/env bash

# [help]
# Umnounts a previously mounted container
#
# Usage: util container unmount <path/to/container>

src="$1"
if [[ -z "$src" ]]; then
  exit 1
fi

dev=$(losetup -n -O NAME -j "$src" | head -n 1)
mapper=$(lsblk -nlo NAME "$dev" | tail -n 1)

udisksctl unmount -b "/dev/mapper/$mapper"
udisksctl lock -b "$dev"

dest="$HOME/$(basename "$src" | rev | cut -f2- -d "." | rev)"
rm -rf "$dest"
mkdir "$dest"
chmod 000 "$dest" # Avoids the poisoning of the destinatio
