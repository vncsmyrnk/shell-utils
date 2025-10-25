#!/bin/sh

# [help]
# Removes a folder from the scripts acessible to the util command

main() {
  if [ -z "$1" ]; then
    echo "Usage: util config remove-script-folder <folder>"
    exit 1
  fi

  destination_path="$SU_SCRIPTS_PATH/$1"
  stow -D -t "$destination_path" "$1" --no-folding
  rm -rf "$destination_path"
}

main "$@"
