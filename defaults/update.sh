#!/bin/sh

# Updates installed apps

UPDATE_GLOBAL_SCRIPT=$HOME/update.sh

main() {
  # Updates package managers
  if exists apt; then sudo apt-get update && sudo apt-get upgrade; fi
  if exists brew; then brew update && brew upgrade; fi
  if exists yay; then yay; fi
  echo "[UTIL] Package managers OK"

  # Checks for global update scripts on utils folder
  [ -x "$SU_SCRIPTS_ON_UPDATE_PATH" ] && {
    echo -e "\n[UTIL] Now updating on-update scripts"
    find $SU_SCRIPTS_ON_UPDATE_PATH \
      -type f \
      -follow \
      -executable \
      -exec echo "found {}." \; \
      -exec {} \;
  }

  # Checks for global update script
  [ -x "$UPDATE_GLOBAL_SCRIPT" ] && {
    echo -e "\n[UTIL] Now using the global update script"
    "$UPDATE_GLOBAL_SCRIPT"
  }
}

exists() {
  command -v "$1" >/dev/null
}

main "$@"
