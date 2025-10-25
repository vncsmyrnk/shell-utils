#!/bin/sh

# Updates installed apps

# [help]
# Updates system packages and runs custom update scripts.
#
# Runs custom scripts located at \033[1m$SU_SCRIPTS_ON_UPDATE_PATH\033[0m and a global script at \033[1m$UPDATE_GLOBAL_SCRIPT\033[0m if available.

UPDATE_GLOBAL_SCRIPT=$HOME/update.sh

main() {
  # Updates package managers
  if exists apt; then sudo apt-get update && sudo apt-get upgrade; fi
  if exists brew; then brew update && brew upgrade; fi
  if exists yay; then yay; fi
  printf "[UTIL] Package managers OK\n"

  # Checks for global update scripts on utils folder
  [ -x "$SU_SCRIPTS_ON_UPDATE_PATH" ] && {
    printf "\n[UTIL] Now updating on-update scripts\n"
    find $SU_SCRIPTS_ON_UPDATE_PATH \
      -type f \
      -follow \
      -executable \
      -exec echo "found {}." \; \
      -exec {} \;
  }

  # Checks for global update script
  [ -x "$UPDATE_GLOBAL_SCRIPT" ] && {
    printf "\n[UTIL] Now using the global update script\n"
    "$UPDATE_GLOBAL_SCRIPT"
  }
}

exists() {
  command -v "$1" >/dev/null
}

main "$@"
exit 0
