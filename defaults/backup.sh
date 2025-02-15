#!/bin/sh

# This script performs a backup of a previously
# defined files

BACKUP_ZIP_FILE_PATH=${BACKUP_ZIP_FILE_PATH:-/tmp/backup.zip}

function main() {
  if [ -z "$UTILS_BKP_PATHS" ]; then
    echo "Please define the environment variable \$UTILS_BKP_PATHS for properly creating the backup zip"
    exit 1
  fi

  rm -f $BACKUP_ZIP_FILE_PATH
  compress_files

  if [ ! -z $BACKUP_ZIP_FILE_PATH ]; then
    backup_size=$(ls -lh $BACKUP_ZIP_FILE_PATH | awk '{ print $5 }')
    echo "Backup file generated at $BACKUP_ZIP_FILE_PATH [$backup_size]"
  fi
}

function compress_files() {
  IFS=' '
  for file_path in $UTILS_BKP_PATHS; do
    if [ -d "$file_path" ]; then
      dir_size=$(du -sh $file_path | awk '{ print $1 }')
      echo "Adding $file_path to be compressed [$dir_size]"
      zip -rq "$BACKUP_ZIP_FILE_PATH" "$file_path"
    elif [ -f "$file_path" ]; then
      file_size=$(ls -lh "$file_path" | awk '{ print $5 }')
      echo "Adding $file_path to be compressed [$file_size]"
      zip -q "$BACKUP_ZIP_FILE_PATH" "$file_path"
    else
      echo "Failed to add $file_path. It does not exist"
    fi
  done
}

main
