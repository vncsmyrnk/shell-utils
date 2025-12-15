#!/bin/sh

# This script performs a backup of a previously
# defined files

# [help]
# Generates an encrypted backup file and uploads it to a rclone remote.
#
# All paths set at \033[1m$SU_BKP_PATHS\033[0m will be copied to the zip backup file. It is predefined with useful paths but it can be overriden.
#
# You must specify \033[1m$SU_SCRIPT_BACKUP_RCLONE_REMOTE\033[0m and \033[1m$SU_SCRIPT_BACKUP_RCLONE_FOLDER\033[0m in order to the backup be automatically uploaded to the remote.

umask 077

SU_SCRIPT_BACKUP_ZIP_DIR=${SU_SCRIPT_BACKUP_ZIP_FILE_PATH:-/tmp}
SU_SCRIPT_BACKUP_ENCRYPTED_DIR=${SU_SCRIPT_BACKUP_ENCRYPTED_DIR:-$SU_SCRIPT_BACKUP_ZIP_DIR}
SU_SCRIPT_BACKUP_ENCRYPT_PASSWORD=${SU_SCRIPT_BACKUP_ENCRYPT_PASSWORD:-""}
SU_SCRIPT_BACKUP_RCLONE_REMOTE=${SU_SCRIPT_BACKUP_RCLONE_REMOTE:-""}
SU_SCRIPT_BACKUP_RCLONE_FOLDER=${SU_SCRIPT_BACKUP_RCLONE_FOLDER:-""}

timestamp=$(date +"%Y%m%d%H%M%S")
SU_SCRIPT_BACKUP_ZIP_FILE_PATH="$SU_SCRIPT_BACKUP_ZIP_DIR/backup_$timestamp.zip"
SU_SCRIPT_BACKUP_ENCRYPTED_FILE_PATH="$SU_SCRIPT_BACKUP_ENCRYPTED_DIR/backup_$timestamp.zip.enc"

main() {
  if [ -z "$SU_BKP_PATHS" ]; then
    printf "Please define the environment variable \$SU_BKP_PATHS for properly creating the backup zip\n"
    exit 1
  fi

  rm -f "$SU_SCRIPT_BACKUP_ZIP_FILE_PATH" "$SU_SCRIPT_BACKUP_ENCRYPTED_FILE_PATH"
  compress_files

  if [ -z "$SU_SCRIPT_BACKUP_ZIP_FILE_PATH" ]; then
    printf "backup failed for unknown reasons\n" >&2
  fi

  backup_size=$(ls -lh "$SU_SCRIPT_BACKUP_ZIP_FILE_PATH" | awk '{ print $5 }')
  printf "Backup file generated at $SU_SCRIPT_BACKUP_ZIP_FILE_PATH [$backup_size]\n"

  encrypt_backup_zip

  upload_backup_zip_to_rclone
  printf "\nBackup successfuly done.\n"
}

compress_files() {
  IFS=' '
  for file_path in $SU_BKP_PATHS; do
    if [ -d "$file_path" ]; then
      dir_size=$(du -sh $file_path | awk '{ print $1 }')
      printf "Adding $file_path to be compressed [$dir_size]\n"
      zip -rq "$SU_SCRIPT_BACKUP_ZIP_FILE_PATH" "$file_path"
    elif [ -f "$file_path" ]; then
      file_size=$(ls -lh "$file_path" | awk '{ print $5 }')
      printf "Adding $file_path to be compressed [$file_size]\n"
      zip -q "$SU_SCRIPT_BACKUP_ZIP_FILE_PATH" "$file_path"
    else
      printf "Failed to add $file_path. It does not exist\n"
    fi
  done

  if ! zip -T "$SU_SCRIPT_BACKUP_ZIP_FILE_PATH" >/dev/null 2>&1; then
    printf "Backup verification failed: zip file is corrupted\n" >&2
    exit 1
  fi
}

upload_backup_zip_to_rclone() {
  if [ -z "$SU_SCRIPT_BACKUP_RCLONE_REMOTE" ] && [ -z "$SU_SCRIPT_BACKUP_RCLONE_FOLDER" ]; then
    printf "rclone is not properly configured and the upload was not done.\n" >&2
    exit 0
  fi

  if ! command -v rclone >/dev/null; then
    printf "Remote copy failed: rclone not found. Ensure the zip is manually saved.\n" >&2
    exit 1
  fi

  if [ ! -f "$SU_SCRIPT_BACKUP_ENCRYPTED_FILE_PATH" ]; then
    printf "Remote copy failed: backup must be encrypted to be uploaded. Enable encryption first.\n"
    exit 0
  fi

  printf "\nNow copying it to remote...\n"
  rclone copy -v "$SU_SCRIPT_BACKUP_ENCRYPTED_FILE_PATH" \
    $SU_SCRIPT_BACKUP_RCLONE_REMOTE:$SU_SCRIPT_BACKUP_RCLONE_FOLDER
}

encrypt_backup_zip() {
  if [ -z "$SU_SCRIPT_BACKUP_ENCRYPT_PASSWORD" ]; then
    printf "file was not encrypted.\n" >&2
    return
  fi

  openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt \
    -in "$SU_SCRIPT_BACKUP_ZIP_FILE_PATH" \
    -out "$SU_SCRIPT_BACKUP_ENCRYPTED_FILE_PATH" \
    -pass env:SU_SCRIPT_BACKUP_ENCRYPT_PASSWORD
  if [ $? -ne 0 ]; then
    printf "encryption failed\n" >&2
    exit 1
  fi
}

main
