#!/bin/sh

# This script performs a backup of a previously
# defined files

# [help]
# Generates an encrypted backup file and uploads it to a rclone remote.
#
# All paths set at \033[1m$SHELL_UTILS_BKP_PATHS\033[0m will be copied to the zip backup file. It is predefined with useful paths but it can be overriden.
#
# You must specify \033[1m$SHELL_UTILS_BACKUP_RCLONE_REMOTE\033[0m and \033[1m$SHELL_UTILS_BACKUP_RCLONE_FOLDER\033[0m in order to the backup be automatically uploaded to the remote.

umask 077

SHELL_UTILS_BKP_PATHS=${SHELL_UTILS_BKP_PATHS:-"$HOME/.zshrc.private $HOME/.env $HOME/Documents $HOME/update.sh $HOME/.password-store"}
SHELL_UTILS_BACKUP_ZIP_DIR=${SHELL_UTILS_BACKUP_ZIP_FILE_PATH:-/tmp}
SHELL_UTILS_BACKUP_ENCRYPTED_DIR=${SHELL_UTILS_BACKUP_ENCRYPTED_DIR:-$SHELL_UTILS_BACKUP_ZIP_DIR}
SHELL_UTILS_BACKUP_ENCRYPT_PASSWORD=${SHELL_UTILS_BACKUP_ENCRYPT_PASSWORD:-""}
SHELL_UTILS_BACKUP_RCLONE_REMOTE=${SHELL_UTILS_BACKUP_RCLONE_REMOTE:-"gdrive"}
SHELL_UTILS_BACKUP_RCLONE_FOLDER=${SHELL_UTILS_BACKUP_RCLONE_FOLDER:-"bkp"}

timestamp=$(date +"%Y%m%d%H%M%S")
SHELL_UTILS_BACKUP_ZIP_FILE_PATH="$SHELL_UTILS_BACKUP_ZIP_DIR/backup_$timestamp.zip"
SHELL_UTILS_BACKUP_ENCRYPTED_FILE_PATH="$SHELL_UTILS_BACKUP_ENCRYPTED_DIR/backup_$timestamp.zip.enc"

main() {
  if [ -z "$SHELL_UTILS_BKP_PATHS" ]; then
    printf "Please define the environment variable \$SHELL_UTILS_BKP_PATHS for properly creating the backup zip\n"
    exit 1
  fi

  rm -f "$SHELL_UTILS_BACKUP_ZIP_FILE_PATH" "$SHELL_UTILS_BACKUP_ENCRYPTED_FILE_PATH"
  compress_files

  if [ -z "$SHELL_UTILS_BACKUP_ZIP_FILE_PATH" ]; then
    printf "backup failed for unknown reasons\n" >&2
  fi

  backup_size=$(ls -lh "$SHELL_UTILS_BACKUP_ZIP_FILE_PATH" | awk '{ print $5 }')
  printf "Backup file generated at $SHELL_UTILS_BACKUP_ZIP_FILE_PATH [$backup_size]\n"

  encrypt_backup_zip

  upload_backup_zip_to_rclone
  printf "\nBackup successfuly done.\n"
}

compress_files() {
  IFS=' '
  for file_path in $SHELL_UTILS_BKP_PATHS; do
    if [ -d "$file_path" ]; then
      dir_size=$(du -sh $file_path | awk '{ print $1 }')
      printf "Adding $file_path to be compressed [$dir_size]\n"
      zip -rq "$SHELL_UTILS_BACKUP_ZIP_FILE_PATH" "$file_path"
    elif [ -f "$file_path" ]; then
      file_size=$(ls -lh "$file_path" | awk '{ print $5 }')
      printf "Adding $file_path to be compressed [$file_size]\n"
      zip -q "$SHELL_UTILS_BACKUP_ZIP_FILE_PATH" "$file_path"
    else
      printf "Failed to add $file_path. It does not exist\n"
    fi
  done

  if ! zip -T "$SHELL_UTILS_BACKUP_ZIP_FILE_PATH" >/dev/null 2>&1; then
    printf "Backup verification failed: zip file is corrupted\n" >&2
    exit 1
  fi
}

upload_backup_zip_to_rclone() {
  if [ -z "$SHELL_UTILS_BACKUP_RCLONE_REMOTE" ] && [ -z "$SHELL_UTILS_BACKUP_RCLONE_FOLDER" ]; then
    printf "rclone is not properly configured and the upload was not done.\n" >&2
    exit 0
  fi

  if ! command -v rclone >/dev/null; then
    printf "Remote copy failed: rclone not found. Ensure the zip is manually saved.\n" >&2
    exit 1
  fi

  if [ ! -f "$SHELL_UTILS_BACKUP_ENCRYPTED_FILE_PATH" ]; then
    printf "Remote copy failed: backup must be encrypted to be uploaded. Enable encryption first.\n"
    exit 0
  fi

  printf "\nNow copying it to remote...\n"
  rclone copy -v "$SHELL_UTILS_BACKUP_ENCRYPTED_FILE_PATH" \
    "$SHELL_UTILS_BACKUP_RCLONE_REMOTE:$SHELL_UTILS_BACKUP_RCLONE_FOLDER"
}

encrypt_backup_zip() {
  if [ -z "$SHELL_UTILS_BACKUP_ENCRYPT_PASSWORD" ]; then
    printf "file was not encrypted.\n" >&2
    return
  fi

  openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt \
    -in "$SHELL_UTILS_BACKUP_ZIP_FILE_PATH" \
    -out "$SHELL_UTILS_BACKUP_ENCRYPTED_FILE_PATH" \
    -pass env:SHELL_UTILS_BACKUP_ENCRYPT_PASSWORD
  if [ $? -ne 0 ]; then
    printf "encryption failed\n" >&2
    exit 1
  fi
}

main
