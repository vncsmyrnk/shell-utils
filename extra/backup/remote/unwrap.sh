#!/bin/bash

# [help]
# Downloads a backup file, decrypts and unzips it
#
# Usage: util backup remote unwrap [--latest] [file]
#
# Tip: use `rsync -av backup dest` to copy the backup files to their destination places

SU_SCRIPT_REMOTE_UNWRAP_DEST=${SU_SCRIPT_REMOTE_UNWRAP_DEST:-/tmp}

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
    printf "list failed: rclone not found." >&2
    exit 1
  fi
}

decrypt_backup() {
  dest_decrypted_file=$(basename "$1" | cut -d '.' -f1)
  dest_decrypted_file="$dest_decrypted_file.$(printf "$1" | cut -d '.' -f2)"
  dest_backup_file="$SU_SCRIPT_REMOTE_UNWRAP_DEST/$dest_decrypted_file"

  openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -salt \
    -in "$1" \
    -out "$dest_backup_file" \
    -pass env:SU_SCRIPT_BACKUP_ENCRYPT_PASSWORD
  if [ $? -ne 0 ]; then
    echo "decryption failed" >&2
    exit 1
  fi

  dest_backup_folder=$(echo "$1" | cut -d '.' -f1)
  unzip -q "$dest_backup_file" -d "$dest_backup_folder" || {
    echo "failed to unzip the backup" >&2
  }
}

main() {
  if [ -z "$SU_SCRIPT_BACKUP_ENCRYPT_PASSWORD" ]; then
    echo "unwrap failed: no password was provided" >&2
    exit 1
  fi

  if [ -n "$1" ] && [ "$latest_flag" = true ]; then
    printf "invalid options. The \033[1m--latest\033[0m implies no other arguments\n" >&2
    exit 1
  elif [ -z "$1" ] && [ "$latest_flag" = false ]; then
    echo "A backup file must be informed." >&2
    exit 1
  fi

  backup_file="$1"
  if [ "$latest_flag" = true ]; then
    echo "Fetching latest backup file..."
    backup_file=$(
      rclone ls "$SU_SCRIPT_BACKUP_RCLONE_REMOTE:$SU_SCRIPT_BACKUP_RCLONE_FOLDER" |
        head -n 1 |
        awk '{ print $2 }'
    )
  fi

  echo "Downloading backup file..."
  rclone copy "$SU_SCRIPT_BACKUP_RCLONE_REMOTE:$SU_SCRIPT_BACKUP_RCLONE_FOLDER/$backup_file" \
    "$SU_SCRIPT_REMOTE_UNWRAP_DEST"

  echo "Decrypting it..."
  decrypt_backup "$SU_SCRIPT_REMOTE_UNWRAP_DEST/$backup_file" || {
    exit 1
  }

  echo "Done. Backup unwrapped at $SU_SCRIPT_REMOTE_UNWRAP_DEST"
}

main "$@"
