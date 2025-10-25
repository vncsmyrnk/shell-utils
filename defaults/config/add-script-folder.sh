#!/bin/sh

# [help]
# Makes a folder of scripts acessible to the util command

main() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: util config add-script-folder <folder> <destination_name>"
    exit 1
  fi

  destination_path="$SU_SCRIPTS_PATH/$2"
  mkdir -p "$destination_path"
  stow -t "$destination_path" "$1" --no-folding
}

main "$@"
