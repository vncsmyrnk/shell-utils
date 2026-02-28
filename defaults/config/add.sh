#!/bin/sh

# [help]
# Makes a script or a folder of scripts acessible to the util command
#
# Creates symbolic links of the sources informed in order to the scripts to be found by util.

SCRIPTS_TARGET_PATH="$SU_SCRIPTS_PATH"

if [ -z "$1" ]; then
  echo "Usage: util config add <file|directory> [-t|--target-name <name>] [-p|--parent-path <path>] [-f|--force] [-d|--dry-run]"
  exit 1
fi

create_symbolic_link_to_dir_target() {
  source="$1"
  target="$2"
  source_basename=$(basename "$source")
  source_dirpath=$(dirname "$source")
  rm -rf "$target"
  mkdir -p "$target"
  stow -t "$target" -d "$source_dirpath" "$source_basename" --no-folding
}

create_symbolic_link_to_file_target() {
  source="$1"
  target="$2"
  rm -f "$target"
  ln -s "$source" "$target"
}

user_confirms_possbile_override() {
  target="$1"
  if [ ! -f "$target" ] && [ ! -d "$target" ]; then
    return
  fi

  printf "There is already a script/folder at this target. Overwrite it? [y/N]: "
  read -r choice
  if [ "$choice" != "y" ] && [ "$choice" != "Y" ]; then
    false
  fi
}

main() {
  source_path=""
  target_name=""
  parent_path=""
  force_overwrite=false
  dry_run=false
  while [ $# -gt 0 ]; do
    case $1 in
    -t | --target-name)
      target_name="$2"
      shift 2
      ;;
    --target-name=*)
      target_name="${1#*=}"
      shift
      ;;
    -p | --parent-path)
      parent_path="$2"
      shift 2
      ;;
    --parent-path=*)
      parent_path="${1#*=}"
      shift
      ;;
    -f | --force)
      force_overwrite=true
      shift
      ;;
    -d | --dry-run)
      dry_run=true
      shift
      ;;
    *)
      source_path="$1"
      shift
      ;;
    esac
  done

  if [ -n "$parent_path" ]; then
    SCRIPTS_TARGET_PATH="$SCRIPTS_TARGET_PATH/$parent_path"
  fi

  source=$(realpath "$source_path")
  target=$(basename "$source")
  if [ -n "$target_name" ]; then
    target="$target_name"
  fi
  target="$SCRIPTS_TARGET_PATH/$target"

  if "$dry_run"; then
    echo "source: $source"
    echo "target: $target"
    echo "dry-run mode detected, no action taken."
    exit 0
  fi

  if ! "$force_overwrite" && ! user_confirms_possbile_override "$target"; then
    exit 1
  fi

  if [ -d "$source" ]; then
    create_symbolic_link_to_dir_target "$source" "$target"
    exit 0
  fi

  create_symbolic_link_to_file_target "$source" "$target"
}

main "$@"
