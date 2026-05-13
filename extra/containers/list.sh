#!/usr/bin/env bash

# [help]
# Lists currently mounted containers
#
# Usage: util containers list
#
# Options:
#  -n, --noheadings    hides headings

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=extra/_lib.sh
\. "$DIR/../_lib.sh"

# shellcheck source=extra/_error.sh
\. "$DIR/../_error.sh"

# shellcheck source=extra/containers/_variables.sh
\. "$DIR/_variables.sh"
: "${_containers_target_name_prefix:=}"

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
  lsblk -Q "NAME =~ '$_containers_target_name_prefix.*'" -np -o PKNAME,MOUNTPOINT,FSUSED,FSSIZE,FSUSE%
)

if [[ -z "$block_devices_result" ]]; then
  _lib_fatal "no active container found."
fi

rows=""
while read -r loop_device mountpoint fs_used fs_size fs_usage; do
  back_file=$(
    losetup "$loop_device" -O BACK-FILE -n
  )
  rows+="$back_file $mountpoint $fs_used $fs_size $fs_usage"$'\n'
done <<<"$block_devices_result"

column_flags=()
if [[ "$no_headings" = false ]]; then
  column_flags+=("-N" "FILE,MOUNTPOINT,USED,SIZE,USAGE")
fi

column -t "${column_flags[@]}" <<<"$rows"
