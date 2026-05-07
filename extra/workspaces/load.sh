#!/usr/bin/env bash

# [help]
# Mounts an encrypted container from a file and stows it on $HOME.
#
# Usage: util workspaces load <path/to/container>

_log_file="$HOME/.cache/shell-utils/container/load-$(date +'%Y%m%d%H%M%S').log"
mkdir -p "$(dirname "$_log_file")"

if ! command -v inotifywait stow >/dev/null 2>&1; then
  echo "inotify-tools and stow are required for this command."
  exit 1
fi

mount_container_blocking() {
  src="$1"
  loop_dev=$(
    udisksctl loop-setup -f "$src" 2>"$_log_file" |
      grep -oP '/dev/loop\d+'
  )
  if [[ -z "$loop_dev" ]]; then
    return 1
  fi

  block_uuid=$(
    lsblk -no UUID "$loop_dev" 2>"$_log_file" |
      head -n 1
  )
  if [[ -z "$block_uuid" ]]; then
    return 1
  fi

  mapper="/dev/mapper/luks-$block_uuid"
  if [[ ! -b "$mapper" ]]; then
    inotifywait -qq -t 30 -e create "/dev/mapper/"
  fi

  if [[ ! -b "$mapper" ]]; then
    echo "failed to mount container."
    udisksctl loop-delete -b "$loop_dev"
    return 1
  fi

  return 0
}

stow_home() {
  src="$1"
  mountpoint=$(
    losetup -j "$src" |
      cut -d: -f1 |
      xargs -I {} lsblk -n -o MOUNTPOINT {} |
      awk 'NF'
  )
  if [[ -z "$mountpoint" ]]; then
    echo "container not mounted"
    exit 1
  fi

  block_uuid=$(
    lsblk -no UUID "$loop_dev" |
      head -n 1
  )
  mapper="/dev/mapper/luks-$block_uuid"

  local mount_dir mount_name
  mount_dir=$(dirname "$mountpoint")
  mount_name=$(basename "$mountpoint")

  stow -d "$mount_dir" -t "$HOME" "$mount_name" || {
    echo "stow failed, unmounting..."
    udisksctl unmount -b "$mapper"
    udisksctl lock -b "$loop_dev"
    return 1
  }

  return 0
}

main() {
  src="$1"
  if [[ -z "$src" ]]; then
    exit 1
  fi

  mountpoint=$(
    losetup -j "$src" |
      cut -d: -f1 |
      xargs -I {} lsblk -n -o MOUNTPOINT {} |
      awk 'NF'
  )
  if [[ -e "$mountpoint" ]]; then
    echo "this container is already mounted at $mountpoint."
    exit 1
  fi

  {
    mount_container_blocking "$src"
    sleep 1
    stow_home "$src"
  } || {
    if [[ -f "$_log_file" ]]; then
      cat "$_log_file"
    fi
    exit 1
  }
}

main "$@"
