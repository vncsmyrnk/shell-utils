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

_mount() {
  local src
  src="$1"

  local loop_device
  loop_device=$(
    udisksctl loop-setup -f "$src" 2>>"$_log_file"
  )
  if [[ "$?" -ne 0 ]]; then
    echo "failed to create loop." >>"$_log_file"
    return 1
  fi
  loop_device=$(grep -oP '/dev/loop\d+' <<<"$loop_device")
  if [[ -z "$loop_device" ]]; then
    udisksctl loop-delete -b "$loop_device"
    return 1
  fi

  local block_uuid
  block_uuid=$(
    lsblk -no UUID "$loop_device" 2>>"$_log_file"
  )
  if [[ "$?" -ne 0 ]]; then
    echo "failed to get block uuid"
    udisksctl loop-delete -b "$loop_device"
    return 1
  fi
  block_uuid=$(head -n 1 <<<"$block_uuid")
  if [[ -z "$block_uuid" ]]; then
    udisksctl loop-delete -b "$loop_device"
    return 1
  fi

  mapper="/dev/mapper/luks-$block_uuid"
  if [[ ! -b "$mapper" ]]; then
    inotifywait -qq -t 30 -e create "/dev/mapper/"
  fi

  if [[ ! -b "$mapper" ]]; then
    echo "failed to mount container." >>"$_log_file"
    udisksctl loop-delete -b "$loop_device"
    return 1
  fi

  return 0
}

_stow() {
  local src
  src="$1"

  local loop_device
  loop_device=$(
    losetup -j "$src"
  )
  loop_device=$(cut -d: -f1 <<<"$loop_device")
  if [[ "$?" -ne 0 ]]; then
    echo "container not mounted" >>"$_log_file"
    return 1
  fi

  local block_uuid
  block_uuid=$(
    lsblk -no UUID "$loop_device"
  )
  block_uuid=$(head -n 1 <<<"$block_uuid")
  if [[ "$?" -ne 0 ]]; then
    echo "failed to get block uuid" >>"$_log_file"
  fi

  local mapper_device
  mapper_device="/dev/mapper/luks-$block_uuid"

  target_path=$(
    findmnt -rn -o TARGET "$mapper_device" 2>>"$_log_file"
  )
  local target_path_dir
  target_path_dir=$(dirname "$target_path")

  local target_name
  target_name=$(basename "$target_path")

  stow -d "$target_path_dir" -t "$HOME" "$target_name" || {
    udisksctl unmount -b "$mapper_device"
    udisksctl lock -b "$loop_device"
    return 1
  }

  return 0
}

_ssh_key_add() {
  key=$(
    find ~/.ssh/ -maxdepth 2 \
      -type f -name "id_*" -not -name "*.pub"
  )
  if [[ -z "$key" ]]; then
    echo "ssh key not found" >>"$_log_file"
    return 1
  fi

  ssh-add "$key" || {
    echo "failed to add ssh key" >>"$_log_file"
    return 1
  }
}

_log_print() {
  if [[ -f "$_log_file" ]]; then
    cat "$_log_file"
  fi
}

main() {
  local src
  src="$1"
  if [[ -z "$src" ]]; then
    exit 1
  fi

  local target
  target=$(
    losetup -j "$src" |
      cut -d: -f1 |
      xargs -I {} lsblk -n -o MOUNTPOINT {} |
      awk 'NF'
  )
  if [[ -n "$target" ]]; then
    echo "this container is already mounted at $target"
    exit 1
  fi

  {
    _mount "$src"
    sleep 1
    _stow "$src"
  } || {
    _log_print
    exit 1
  }

  if ! _ssh_key_add; then
    _log_print
    exit 1
  fi
}

main "$@"
