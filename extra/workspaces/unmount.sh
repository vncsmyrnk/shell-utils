#!/usr/bin/env bash

# [help]
# Unmounts an encrypted workspace container
#
# Usage: util workspaces unmount <path/to/container>

_log_file="$HOME/.cache/shell-utils/container/unmount-$(date +'%Y%m%d%H%M%S').log"
mkdir -p "$(dirname "$_log_file")"

_unmount() {
  target_name="$1"
  target="$2"

  sudo -v

  sudo umount "$target" || {
    echo "failed to unmount container." >"$_log_file"
    return 1
  }

  sudo cryptsetup close "$target_name" || {
    echo "failed to close container." >"$_log_file"
    return 1
  }
}

main() {
  target="$1"
  if [[ -z "$target" ]]; then
    exit 1
  fi

  target_name=$(basename "$target")
  _unmount "$target_name" "$target"
}

main "$@"
