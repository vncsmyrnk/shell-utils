#!/bin/sh

# help: lists backups uploaded to the current set rclone remote

if ! command -v rclone >/dev/null; then
  echo "list failed: rclone not found." >&2
  exit 1
fi

rclone ls $SU_SCRIPT_BACKUP_RCLONE_REMOTE:$SU_SCRIPT_BACKUP_RCLONE_FOLDER
