#!/usr/bin/env bash
set -e

# [help]
# Lists backups uploaded to the current set rclone remote

: "${SHELL_UTILS_SCRIPTS_PATH:=}"
# shellcheck source=scripts/_lib.sh
\. "${SHELL_UTILS_SCRIPTS_PATH}/_lib.sh"

SHELL_UTILS_BACKUP_RCLONE_REMOTE=${SHELL_UTILS_BACKUP_RCLONE_REMOTE:-"gdrive"}
SHELL_UTILS_BACKUP_RCLONE_FOLDER=${SHELL_UTILS_BACKUP_RCLONE_FOLDER:-"bkp"}

if ! command -v rclone >/dev/null; then
  _lib_fatal "list failed: rclone not found."
fi

files=$(rclone ls "$SHELL_UTILS_BACKUP_RCLONE_REMOTE:$SHELL_UTILS_BACKUP_RCLONE_FOLDER")
if [[ -z "$files" ]]; then
  echo "no files found." >&2
fi

awk '{ print $2 }' <<<"$files"
