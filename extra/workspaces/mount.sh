#!/usr/bin/env bash

# [help]
# Mounts an encrypted workspace container from a file
#
# Usage: util workspaces mount <path/to/container> <path/to/target>

_log_file="$HOME/.cache/shell-utils/container/mount-$(date +'%Y%m%d%H%M%S').log"
mkdir -p "$(dirname "$_log_file")"

_mount() {
  src="$1"
  target_name="$2"
  target="$3"

  sudo -v

  sudo cryptsetup open "$src" "$target_name" || {
    echo "failed to open container." >"$_log_file"
    return 1
  }

  sudo mount "/dev/mapper/$target_name" "$target" || {
    echo "failed to mount container." >"$_log_file"
    sudo cryptsetup close "$target_name"
    return 1
  }
}

main() {
  src="$1"
  target="$2"
  if [[ -z "$target" ]]; then
    exit 1
  fi

  target_name=$(basename "$target")
  _mount "$src" "$target_name" "$target"
}

main "$@"
