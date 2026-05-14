#!/bin/bash

# [help]
# Downloads a backup file, decrypts and unzips it
#
# Usage: util backup remote unwrap [FILE] [OPTIONS]
#
# Options:
#  -l, --latest   Fetch the latest backup available
#
# Tip: use `rsync -av backup dest` to copy the backup files to their destination places

# shellcheck source=extra/_lib.sh
\. "./../../_lib.sh"

# shellcheck source=extra/_error.sh
\. "./../../_error.sh"

SHELL_UTILS_BACKUP_RCLONE_REMOTE=${SHELL_UTILS_BACKUP_RCLONE_REMOTE:-"gdrive"}
SHELL_UTILS_BACKUP_RCLONE_FOLDER=${SHELL_UTILS_BACKUP_RCLONE_FOLDER:-"bkp"}
SHELL_UTILS_REMOTE_UNWRAP_DEST=${SHELL_UTILS_REMOTE_UNWRAP_DEST:-/tmp}
SHELL_UTILS_BACKUP_ENCRYPT_PASSWORD=${SHELL_UTILS_BACKUP_ENCRYPT_PASSWORD:-""}

latest_flag=false
while [[ $# -gt 0 ]]; do
  case $1 in
  -l | --latest)
    latest_flag=true
    shift
    ;;
  *)
    break
    ;;
  esac
done

check_dependencies() {
  if ! command -v rclone >/dev/null; then
    _lib_fatal "dependencies: rclone not found."
  fi
}

decrypt_backup() {
  dest_decrypted_file=$(basename "$1" | cut -d '.' -f1)
  dest_decrypted_file="$dest_decrypted_file.$(cut -d '.' -f2 <<<"$dest_decrypted_file")"
  dest_backup_file="$SHELL_UTILS_REMOTE_UNWRAP_DEST/$dest_decrypted_file"

  openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -salt \
    -in "$1" \
    -out "$dest_backup_file" \
    -pass env:SHELL_UTILS_BACKUP_ENCRYPT_PASSWORD

  dest_backup_folder=$(cut -d '.' -f1 <<<"$1")
  unzip -q "$dest_backup_file" -d "$dest_backup_folder"
}

main() {
  if [[ -z "$SHELL_UTILS_BACKUP_ENCRYPT_PASSWORD" ]]; then
    _lib_fatal "unwrap failed: no password was provided"
  fi

  if [[ -n "$1" ]] && [[ "$latest_flag" = true ]]; then
    _lib_fatal "invalid options. The \033[1m--latest\033[0m implies no other arguments\n"
  elif [[ -z "$1" ]] && [[ "$latest_flag" = false ]]; then
    _lib_fatal "A backup file must be informed."
  fi

  backup_file="$1"
  if [[ "$latest_flag" = true ]]; then
    echo "Fetching latest backup file..."
    files=$(rclone ls "$SHELL_UTILS_BACKUP_RCLONE_REMOTE:$SHELL_UTILS_BACKUP_RCLONE_FOLDER")
    last_file_output=$(head -n 1 <<<"$files")
    backup_file=$(awk '{ print $1 }' <<<"$last_file_output")
  fi

  echo "Downloading backup file..."
  rclone copy "$SHELL_UTILS_BACKUP_RCLONE_REMOTE:$SHELL_UTILS_BACKUP_RCLONE_FOLDER/$backup_file" \
    "$SHELL_UTILS_REMOTE_UNWRAP_DEST"

  echo "Decrypting it..."
  decrypt_backup "$SHELL_UTILS_REMOTE_UNWRAP_DEST/$backup_file"

  echo "Done. Backup unwrapped at $SHELL_UTILS_REMOTE_UNWRAP_DEST"
}

main "$@"
