#!/bin/sh

# This script performs a backup of a previously
# defined files

SU_SCRIPT_BACKUP_ZIP_FILE_PATH=${SU_SCRIPT_BACKUP_ZIP_FILE_PATH:-/tmp/backup.zip}
SU_SCRIPT_BACKUP_RCLONE_REMOTE=${SU_SCRIPT_BACKUP_RCLONE_REMOTE:-""}
SU_SCRIPT_BACKUP_RCLONE_FOLDER=${SU_SCRIPT_BACKUP_RCLONE_FOLDER:-""}

main() {
  if [ -z "$SU_BKP_PATHS" ]; then
    echo "Please define the environment variable \$SU_BKP_PATHS for properly creating the backup zip"
    exit 1
  fi

  rm -f $SU_SCRIPT_BACKUP_ZIP_FILE_PATH
  compress_files

  if [ -z $SU_SCRIPT_BACKUP_ZIP_FILE_PATH ]; then
    echo "backup failed for unknown reasons" >&2
  fi

  backup_size=$(ls -lh $SU_SCRIPT_BACKUP_ZIP_FILE_PATH | awk '{ print $5 }')
  echo "Backup file generated at $SU_SCRIPT_BACKUP_ZIP_FILE_PATH [$backup_size]"

  upload_backup_zip_to_rclone
  echo "\nBackup successfuly done."
}

compress_files() {
  IFS=' '
  for file_path in $SU_BKP_PATHS; do
    if [ -d "$file_path" ]; then
      dir_size=$(du -sh $file_path | awk '{ print $1 }')
      echo "Adding $file_path to be compressed [$dir_size]"
      zip -rq "$SU_SCRIPT_BACKUP_ZIP_FILE_PATH" "$file_path"
    elif [ -f "$file_path" ]; then
      file_size=$(ls -lh "$file_path" | awk '{ print $5 }')
      echo "Adding $file_path to be compressed [$file_size]"
      zip -q "$SU_SCRIPT_BACKUP_ZIP_FILE_PATH" "$file_path"
    else
      echo "Failed to add $file_path. It does not exist"
    fi
  done
}

upload_backup_zip_to_rclone() {
  if [ -z $SU_SCRIPT_BACKUP_RCLONE_REMOTE ] && [ -z $SU_SCRIPT_BACKUP_RCLONE_FOLDER ]; then
    echo "rclone is not properly configured and the upload was not done." >&2
    exit 0
  fi

  if ! command -v rclone >/dev/null; then
    echo "Remote copy failed: rclone not found. Ensure the zip is manually saved." >&2
    exit 1
  fi

  echo "\nNow copying it to remote..."
  rclone copy -v $SU_SCRIPT_BACKUP_ZIP_FILE_PATH \
    $SU_SCRIPT_BACKUP_RCLONE_REMOTE:$SU_SCRIPT_BACKUP_RCLONE_FOLDER
}

main
