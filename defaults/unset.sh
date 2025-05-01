#!/bin/sh

# Completions
# --scripts[Unsows scripts on scripts folder]:
# --setups[Unstows setups on setups folder]:

# This command centralizes all configurable actions for
# setting options

lib_file="$SU_SCRIPTS_PATH/_lib.sh"
[ -f "$lib_file" ] || {
  printf "failed to source lib file"
  exit 1
}

\. "$lib_file"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --scripts)
      arg_value="$2"
      shift 2
      unstow_to_scripts_path $arg_value
      ;;
    --setups)
      arg_value="$2"
      shift 2
      unstow_to_setup_path $arg_value
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done
