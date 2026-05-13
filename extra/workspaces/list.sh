#!/usr/bin/env bash

# [help]
# Lists currently mounted workspace containers
#
# Usage: util workspaces list
#
# Options:
#  -n, --noheadings   Hide headings

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=extra/_lib.sh
\. "$DIR/../_lib.sh"

# shellcheck source=extra/_error.sh
\. "$DIR/../_error.sh"

# shellcheck source=extra/workspaces/_variables.sh
\. "$DIR/_variables.sh"
: "${_workspaces_mount_path:=}"

no_headings=false
while [[ $# -gt 0 ]]; do
  case $1 in
  -n | --noheadings)
    no_headings=true
    shift
    ;;
  *)
    break
    ;;
  esac
done

block_devices_result=$(
  lsblk -Q "MOUNTPOINT =~ '$_workspaces_mount_path'" -np -o PKNAME,FSUSED,FSSIZE,FSUSE%
)

if [[ -z "$block_devices_result" ]]; then
  echo "no active workspace found."
  exit 1
fi

rows=""
while read -r loop_device fs_used fs_size fs_usage; do
  back_file=$(
    losetup "$loop_device" -O BACK-FILE -n
  )
  rows+="$back_file $fs_used $fs_size $fs_usage"$'\n'
done <<<"$block_devices_result"

column_flags=()
if [[ "$no_headings" = false ]]; then
  column_flags+=("-N" "FILE,USED,SIZE,USAGE")
fi

column -t "${column_flags[@]}" <<<"$rows"
