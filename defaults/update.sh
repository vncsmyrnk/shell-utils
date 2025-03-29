#!/bin/sh

# Updates installed apps

MANUALLY_INSTALLED_LOCATION=/usr/local/stow
UPDATE_GLOBAL_SCRIPT=$HOME/update.sh

main() {
  # Updates package managers
  if exists apt; then sudo apt-get update && sudo apt-get upgrade; fi
  if exists brew; then brew update && brew upgrade; fi
  if exists yay; then yay; fi
  echo "[UTIL] Package managers OK"

  # Updates manually installed applications
  [ -d $MANUALLY_INSTALLED_LOCATION ] && {
    echo "[UTIL] Now updating manually installed"
    for app in "$MANUALLY_INSTALLED_LOCATION"/*; do
      echo "Checking $app..."
      app_name=$(basename "$app")
      find $SU_SCRIPTS_PATH/$app_name \
        -iname "update.*" \
        -type f \
        -follow \
        -executable \
        -exec {} \;
    done
  }

  # Checks for global update scripts on utils folder
  [ -x "$SU_SCRIPTS_ON_UPDATE_PATH" ] && {
    echo "[UTIL] Now updating on-update scripts"
    find $SU_SCRIPTS_ON_UPDATE_PATH \
      -type f \
      -follow \
      -executable \
      -exec {} \;
  }

  # Checks for global update script
  [ -x "$UPDATE_GLOBAL_SCRIPT" ] && {
    echo "[UTIL] Now using the global update script"
    "$UPDATE_GLOBAL_SCRIPT"
  }
}

exists() {
  command -v "$1" >/dev/null
}

main "$@"
