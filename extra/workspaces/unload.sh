#!/usr/bin/env bash

# [help]
# Umnounts a previously mounted container
#
# Unmounts all containers from a directory if a directory is used.
#
# Usage: util workspaces unload <path/to/container>

_log_file="$HOME/.cache/shell-utils/container/unload-$(date +'%Y%m%d%H%M%S').log"
mkdir -p "$(dirname "$_log_file")"

_unmount() {
  local src
  src="$1"

  local loop_device
  loop_device=$(losetup -n -O NAME -j "$src")
  if [[ "$?" -ne 0 ]]; then
    echo "failed to get loop device" >"$_log_file"
    return 1
  fi
  loop_device=$(head -n 1 <<<"$loop_device")

  container_mapper=$(
    lsblk -nlo NAME "$loop_device" 2>"$_log_file"
  )
  if [[ "$?" -ne 0 ]]; then
    echo "failed to get container mapper" >"$_log_file"
    return 1
  fi
  container_mapper=$(tail -n 1 <<<"$container_mapper")
  if [[ -z "$container_mapper" ]]; then
    echo "failed to find container mapper path." >"$_log_file"
    return 1
  fi

  mapper_device="/dev/mapper/$container_mapper"
  target_path=$(
    findmnt -rn -o TARGET "$mapper_device" 2>"$_log_file"
  )
  if [[ "$?" -ne 0 ]] || [[ -z "$target_path" ]]; then
    echo "failed to find container target path." >"$_log_file"
    return 1
  fi

  target_path_dir=$(dirname "$target_path")
  target_name=$(basename "$target_path")
  stow -D -d "$target_path_dir" -t "$HOME" "$target_name" || {
    echo "failed to unstow" >"$_log_file"
    return 1
  }

  {
    udisksctl unmount -b "$mapper_device"
    udisksctl lock -b "$loop_device"
  } || {
    echo "files were unstowed but the unmount failed." >"$_log_file"
    return 1
  }

  ssh-add -D || {
    echo "failed to clear ssh entities." >"$_log_file"
    return 1
  }
}

_log_print() {
  if [[ -f "$_log_file" ]]; then
    cat "$_log_file"
  fi
}

main() {
  src="$1"
  if [[ -z "$src" ]]; then
    exit 1
  fi

  if [[ -d "$src" ]]; then
    for f in "$src"/*; do
      _unmount "$f" || {
        _log_print
        exit 1
      }
    done
    exit 0
  fi

  _unmount "$src" || {
    _log_print
    exit 1
  }
}

main "$@"
