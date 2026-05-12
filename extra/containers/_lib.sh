#!/usr/bin/env bash

_container_mount() {
  local src
  src="$1"

  local target_name
  target_name="$2"

  local target
  target="$3"

  sudo -v

  if ! open_result=$(sudo cryptsetup open "$src" "$target_name"); then
    echo "failed to open container." >&2
    echo "$open_result" >&2
    return 1
  fi

  mkdir -p "$target"
  mapper_path="/dev/mapper/$target_name"

  if ! mount_result=$(sudo mount "$mapper_path" "$target"); then
    echo "failed to mount container." >&2
    echo "$mount_result" >&2
    sudo cryptsetup close "$target_name"
    return 1
  fi
}

_container_mounted() {
  local src
  src="$1"

  local loop_device
  if ! loop_device=$(losetup -j "$src" 2>&1); then
    echo "failed to fetch loop device." >&2
    echo "$target" >&2
    return 1
  fi

  if [[ -z "$loop_device" ]]; then
    echo "device not mounted" >&2
    return 1
  fi

  if ! mountpoint=$(
    lsblk -n -o MOUNTPOINT "$(cut -d: -f1 <<<"$loop_device")" 2>&1 |
      awk 'NF'
  ); then
    echo "failed to fetch mountpoint." >&2
    echo "$mountpoint" >&2
  fi

  echo "$mountpoint"
  return 0
}

_container_unmount() {
  target_name="$1"
  target="$2"

  sudo -v

  if ! unmount_result=$(sudo umount "$target"); then
    echo "failed to unmount container." >&2
    echo "$unmount_result" >&2
    return 1
  fi

  if ! close_result=$(sudo cryptsetup close "$target_name"); then
    echo "failed to close container." >&2
    echo "$close_result" >&2
    return 1
  fi

  rm -rf "$target"
}
