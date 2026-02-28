#!/bin/sh

# [help]
# Removes a folder from the scripts acessible to the util command

SCRIPTS_TARGET_PATH="$SU_SCRIPTS_PATH"

user_confirmed_removal() {
  printf "Are you sure? [y/N]: "
  read -r choice
  if [ "$choice" != "y" ] && [ "$choice" != "Y" ]; then
    false
  fi
}

main() {
  target_name=""
  dry_run=false
  while [ $# -gt 0 ]; do
    case $1 in
    -d | --dry-run)
      dry_run=true
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

  if "$dry_run"; then
    echo "scripts to be removed:"
    find "$SCRIPTS_TARGET_PATH" \
      -path "$SCRIPTS_TARGET_PATH/$target_name*" \
      -follow \
      -executable \
      -type f \
      -not -name "on-update*" \
      -not -name "_*" \
      -printf "%P\n"
    echo "dry-run mode detected, no action taken."
    exit 0
  fi

  destination_path="$SCRIPTS_TARGET_PATH/$target_name"
  if [ -d "$destination_path" ]; then
    if ! user_confirmed_removal; then
      exit 1
    fi
    rm -rf "$destination_path"
    exit 0
  fi

  for f in "$destination_path".*; do
    if ! user_confirmed_removal; then
      exit 1
    fi
    rm -f "$f"
    exit 0
  done

  echo "Failed to find script that matches the query"
  exit 1
}

main "$@"
