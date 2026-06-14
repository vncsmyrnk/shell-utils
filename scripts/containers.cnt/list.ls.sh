#!/usr/bin/env bash
set -e

# [help]
# Lists currently mounted containers
#
# Usage: util containers list [OPTIONS]
#
# Options:
#  -n, --noheadings   Hide heading
#  -p, --full-path    Display full container source path

: "${SHELL_UTILS_SCRIPTS_PATH:=}"
# shellcheck source=scripts/_lib.sh
\. "${SHELL_UTILS_SCRIPTS_PATH}/_lib.sh"

: "${SHELL_UTILS_SCRIPT_DIRNAME:=}"
# shellcheck source=scripts/containers.cnt/_variables.sh
\. "${SHELL_UTILS_SCRIPT_DIRNAME}/_variables.sh"

: "${_containers_target_name_prefix:=}"

no_headings=false
full_path=false
while [[ $# -gt 0 ]]; do
  case $1 in
  -n | --noheadings)
    no_headings=true
    shift
    ;;
  -p | --full-path)
    full_path=true
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
  # shellcheck disable=SC2310,SC2311
  if [[ "$full_path" = false ]] && container_ref=$(_lib_files_filename_noext "$back_file" || true) &&
    [[ -f "$HOME/.config/shell-utils/containers/$container_ref.json" ]]; then
    back_file="$container_ref"
  fi
  rows+="$back_file $mountpoint $fs_used $fs_size $fs_usage"$'\n'
done <<<"$block_devices_result"

column_flags=()
if [[ "$no_headings" = false ]]; then
  column_flags+=("-N" "FILE,MOUNTPOINT,USED,SIZE,USAGE")
fi

column -t "${column_flags[@]}" <<<"$rows"
