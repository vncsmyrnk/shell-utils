#!/usr/bin/env bash
set -e

# [help]
# Unmounts an encrypted container
#
# Usage: util containers unmount [CONTAINER]

: "${SHELL_UTILS_SCRIPTS_PATH:=}"
# shellcheck source=scripts/_lib.sh
\. "${SHELL_UTILS_SCRIPTS_PATH}/_lib.sh"

: "${SHELL_UTILS_SCRIPT_DIRNAME:=}"
# shellcheck source=scripts/containers.cnt/_lib.sh
\. "${SHELL_UTILS_SCRIPT_DIRNAME}/_lib.sh"

# shellcheck source=scripts/containers.cnt/_variables.sh
\. "${SHELL_UTILS_SCRIPT_DIRNAME}/_variables.sh"

: "${_containers_target_name_prefix:=}"

src=
force=false
while [[ $# -gt 0 ]]; do
  case $1 in
  -f | --force)
    force=true
    shift
    ;;
  --)
    shift
    break
    ;;
  *)
    if [[ -n "$src" ]]; then
      echo "Unexpected extra argument \"$1\""
      break
    fi
    src="$1"
    shift
    ;;
  esac
done

if [[ ! -f "$src" ]]; then
  src="$_containers_image_dir/$src.img"
  if [[ ! -f "$src" ]]; then
    _lib_fatal "container file not found."
  fi
fi

target=$(
  set -e
  _container_mounted "$src"
)

# shellcheck disable=SC2310,SC2311
if ! target=$(_container_mounted "$src"); then
  echo "$target" >&2
  exit 1
fi

if fuser -s -m "$target"; then
  if [[ "$force" = false ]]; then
    fuser -v -m "$target"
    read -r -p "kill and procceed? (y/N) " answer
    if [[ ! "$answer" =~ ^([Yy])$ ]]; then
      exit 1
    fi
  fi
  fuser -s -m "$target" -k
fi

target_name=$(
  set -e
  _lib_files_filename_noext "$target"
)

target_name="$_containers_target_name_prefix$target_name"
_container_unmount "$target_name" "$target"
