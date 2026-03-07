#!/bin/sh

# [help]
# Lists backups uploaded to the current set rclone remote

SHELL_UTILS_BACKUP_RCLONE_REMOTE=${SHELL_UTILS_BACKUP_RCLONE_REMOTE:-"gdrive"}
SHELL_UTILS_BACKUP_RCLONE_FOLDER=${SHELL_UTILS_BACKUP_RCLONE_FOLDER:-"bkp"}

if ! command -v rclone >/dev/null; then
  echo "list failed: rclone not found." >&2
  exit 1
fi

rclone ls "$SHELL_UTILS_BACKUP_RCLONE_REMOTE:$SHELL_UTILS_BACKUP_RCLONE_FOLDER" |
  awk '{ print $2 }'
