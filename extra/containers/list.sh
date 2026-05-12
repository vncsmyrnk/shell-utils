#!/usr/bin/env bash

# [help]
# Lists currently mounted containers
#
# Usage: util containers list
#
# Options:
#  -n, --noheadings    hides headings

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
\. "$DIR/_variables.sh"

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
  lsblk -Q "NAME =~ '$_containers_target_name_prefix.*'" -np -o PKNAME,FSUSED,FSSIZE,FSUSE% 2>&1
)
if [[ "$?" -ne 0 ]]; then
  echo "failed to list mounted devices."
  echo "$block_devices_result"
  exit 1
fi

if [[ -z "$block_devices_result" ]]; then
  echo "no active container found."
  exit 1
fi

rows=""
while read -r loop_device fs_used fs_size fs_usage; do
  back_file=$(
    losetup "$loop_device" -O BACK-FILE -n 2>&1
  )
  if [[ "$?" -ne 0 ]]; then
    echo "$back_file" >&2
    exit 1
  fi
  rows+="$back_file $fs_used $fs_size $fs_usage"
done <<<"$block_devices_result"

column_flags=()
if [[ "$no_headings" = false ]]; then
  column_flags+=("-N" "File,Used,Size,Usage")
fi

column -t "${column_flags[@]}" <<<"$rows"
