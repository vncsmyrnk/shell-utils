#!/usr/bin/env bash

# [help]
# Umnounts a previously mounted container
#
# Unmounts all containers from a directory if a directory is used.
#
# Usage: util workspaces unload <path/to/container>

_log_file="$HOME/.cache/shell-utils/container/unload-$(date +'%Y%m%d%H%M%S').log"
mkdir -p "$(dirname "$_log_file")"

unmount_container() {
  src="$1"

  dev=$(losetup -n -O NAME -j "$src" | head -n 1)
  mapper=$(
    lsblk -nlo NAME "$dev" 2>"$_log_file" |
      tail -n 1
  )
  if [[ -z "$mapper" ]]; then
    echo "failed to find container mapper path."
    return 1
  fi

  mounted_path=$(findmnt -rn -o TARGET "/dev/mapper/$mapper" 2>"$_log_file")
  if [[ -z "$mounted_path" ]]; then
    echo "failed to find container mounted path."
    return 1
  fi

  mounted_path_dirname=$(dirname "$mounted_path")
  mounted_path_basename=$(basename "$mounted_path")
  stow -D -d "$mounted_path_dirname" -t "$HOME" "$mounted_path_basename" || {
    echo "failed to unstow"
    exit 1
  }

  {
    udisksctl unmount -b "/dev/mapper/$mapper"
    udisksctl lock -b "$dev"
  } || {
    echo "files were unstowed but the unmount failed."
    exit 1
  }
}

main() {
  src="$1"
  if [[ -z "$src" ]]; then
    exit 1
  fi

  if [[ -d "$src" ]]; then
    for f in "$src"/*; do
      unmount_container "$f" || {
        if [[ -f "$_log_file" ]]; then
          cat "$_log_file"
        fi
        exit 1
      }
    done
    exit 0
  fi

  unmount_container "$src" || {
    if [[ -f "$_log_file" ]]; then
      cat "$_log_file"
    fi
    exit 1
  }
}

main "$@"
