#!/usr/bin/env bash

# [help]
# Lists backups uploaded to the current set rclone remote

# shellcheck source=extra/_error.sh
if ! e=$(util-fetch "$(realpath "./../../_error.sh" || true)"); then
  exit 1
fi
\. <(echo "$e")

# shellcheck source=extra/_lib.sh
if ! e=$(util-fetch "$(realpath "./../../_lib.sh" || true)"); then
  exit 1
fi
\. <(echo "$e")

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
