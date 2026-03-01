#!/bin/sh

# [help]
# Removes a folder from the scripts acessible to the util command

TARGET_PATH="$SU_PATH"

user_confirmed_removal() {
  printf "Are you sure? [y/N]: "
  read -r choice
  if [ "$choice" != "y" ] && [ "$choice" != "Y" ]; then
    false
  fi
}

remove_directory() {
  target="$1"
  original_source="$2"
  force_removal="$3"
  if ! "$force_removal" && ! user_confirmed_removal; then
    exit 1
  fi

  if [ -n "$original_source" ]; then
    original_basename=$(basename "$original_source")
    original_dirname=$(dirname "$original_source")
    stow -D -t "$target" -d "$original_dirname" "$original_basename"
    exit 0
  fi
  rm -rf "$target"
}

main() {
  target_name=""
  original_source=""
  force_removal=false
  while [ $# -gt 0 ]; do
    case $1 in
    -s | --original-source)
      original_source="$2"
      shift 2
      ;;
    --original-source=*)
      original_source="${1#*=}"
      shift
      ;;
    -f | --force)
      force_removal=true
      shift
      ;;
    *)
      target_name="$1"
      shift
      ;;
    esac
  done

  if [ -z "$target_name" ]; then
    echo "Usage: util config remove <target>"
    exit 1
  fi

  target="$TARGET_PATH/$target_name"
  if [ -d "$target" ]; then
    remove_directory "$target" "$original_source" "$force_removal"
    exit 0
  fi

  for f in "$target".*; do
    if ! "$force_removal" && ! user_confirmed_removal; then
      exit 1
    fi
    rm -f "$f"
    exit 0
  done

  echo "Failed to find script that matches the query"
  exit 1
}

main "$@"
