#!/usr/bin/env bash

_container_mount() {
  local src
  src="$1"

  local target_name
  target_name="$2"

  local target
  target="$3"

  sudo -v

  if ! sudo cryptsetup open "$src" "$target_name"; then
    return 1
  fi

  mkdir -p "$target"
  mapper_path="/dev/mapper/$target_name"

  if ! sudo mount "$mapper_path" "$target"; then
    sudo cryptsetup close "$target_name"
    return 1
  fi
}

_container_mounted() {
  local src
  src="$1"

  local loop_device
  loop_device=$(losetup -j "$src" -O NAME -n)

  if [[ -z "$loop_device" ]]; then
    echo "device not mounted" >&2
    return 1
  fi

  if ! mountpoint=$(
    lsblk "$loop_device" -Q 'MOUNTPOINT' -np -o MOUNTPOINT
  ); then
    return 1
  fi

  echo "$mountpoint"
  return 0
}

_container_unmount() {
  target_name="$1"
  target="$2"

  if fuser -s -m "$target"; then
    echo "target is busy." >&2
    return 1
  fi

  sudo -v

  if ! sudo umount "$target"; then
    return 1
  fi

  if ! sudo cryptsetup close "$target_name"; then
    return 1
  fi

  rm -rf "$target"
}
