#!/usr/bin/env bash

# [help]
# Lists currently mounted containers
#
# Usage: util containers list

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
\. "$DIR/_variables.sh"

loop_devices_result=$(
  lsblk -Q "NAME =~ '$_containers_target_name_prefix.*'" -n -o PKNAME 2>&1
)
if [[ "$?" -ne 0 ]]; then
  echo "failed to list mounted devices."
  echo "$loop_devices_result"
  exit 1
fi

if [[ -z "$loop_devices_result" ]]; then
  echo "no active workspace found."
  exit 1
fi

readarray -t loop_devices <<<"$loop_devices_result"
for loop_device in "$loop_devices"; do
  loop_device_path="/dev/$loop_device"
  back_file=$(
    losetup "$loop_device_path" -O BACK-FILE -n
  )
  echo "$back_file"
done
