#!/usr/bin/env bash
set -e

# [help]
# Generates an encrypted backup file and uploads it to a rclone remote
#
# All paths set at \033[1m$SHELL_UTILS_BKP_PATHS\033[0m will be copied to the zip backup file. It is predefined with useful paths but it can be overriden. You must specify \033[1m$SHELL_UTILS_BACKUP_RCLONE_REMOTE\033[0m and \033[1m$SHELL_UTILS_BACKUP_RCLONE_FOLDER\033[0m in order to the backup be automatically uploaded to the remote.
#
# Usage: util backup generate [OPTIONS]
#
# Options:
#   -b,--bypass-password   Bypasses encryption password confirmation

: "${SHELL_UTILS_SCRIPTS_PATH:=}"
# shellcheck source=scripts/_lib.sh
\. "${SHELL_UTILS_SCRIPTS_PATH}/_lib.sh"

umask 077

SHELL_UTILS_BKP_PATHS=${SHELL_UTILS_BKP_PATHS:-"$HOME/.zshrc.private $HOME/.env $HOME/Documents $HOME/update.sh $HOME/.password-store $HOME/.shell-utils"}
SHELL_UTILS_BACKUP_ZIP_DIR=${SHELL_UTILS_BACKUP_ZIP_FILE_PATH:-/tmp}
SHELL_UTILS_BACKUP_ENCRYPTED_DIR=${SHELL_UTILS_BACKUP_ENCRYPTED_DIR:-$SHELL_UTILS_BACKUP_ZIP_DIR}
SHELL_UTILS_BACKUP_ENCRYPT_PASSWORD=${SHELL_UTILS_BACKUP_ENCRYPT_PASSWORD:-""}
SHELL_UTILS_BACKUP_RCLONE_REMOTE=${SHELL_UTILS_BACKUP_RCLONE_REMOTE:-"gdrive"}
SHELL_UTILS_BACKUP_RCLONE_FOLDER=${SHELL_UTILS_BACKUP_RCLONE_FOLDER:-"bkp"}

timestamp=$(date +"%Y%m%d%H%M%S")
SHELL_UTILS_BACKUP_ZIP_FILE_PATH="$SHELL_UTILS_BACKUP_ZIP_DIR/backup_$timestamp.zip"
SHELL_UTILS_BACKUP_ENCRYPTED_FILE_PATH="$SHELL_UTILS_BACKUP_ENCRYPTED_DIR/backup_$timestamp.zip.enc"

main() {
  bypass_password=false
  while [[ $# -gt 0 ]]; do
    case $1 in
    -b | --bypass-password)
      bypass_password=true
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
    esac
  done

  if [[ -z "$SHELL_UTILS_BKP_PATHS" ]]; then
    _lib_fatal "please define the environment variable \$SHELL_UTILS_BKP_PATHS for properly creating the backup zip" >&2
  fi

  if [[ -z "$SHELL_UTILS_BACKUP_ENCRYPT_PASSWORD" ]]; then
    echo "encrypt password was not provided." >&2
    return 1
  fi

  rm -f "$SHELL_UTILS_BACKUP_ZIP_FILE_PATH" "$SHELL_UTILS_BACKUP_ENCRYPTED_FILE_PATH"

  # shellcheck disable=SC2310
  if ! compress_files; then
    exit 1
  fi

  backup_size_output=$(du -h "$SHELL_UTILS_BACKUP_ZIP_FILE_PATH")
  backup_size=$(awk '{ print $1 }' <<<"$backup_size_output")
  echo "backup file generated at $SHELL_UTILS_BACKUP_ZIP_FILE_PATH [$backup_size]"

  # shellcheck disable=SC2310
  if ! encrypt_backup_zip "$bypass_password"; then
    exit 1
  fi

  # shellcheck disable=SC2310
  if ! upload_backup_zip_to_rclone; then
    exit 1
  fi
  echo -e "\nbackup successfuly done."
}

compress_files() {
  IFS=' '
  for file_path in $SHELL_UTILS_BKP_PATHS; do
    if [[ -d "$file_path" ]]; then
      dir_size_output=$(du -sh "$file_path")
      dir_size=$(awk '{ print $1 }' <<<"$dir_size_output")
      echo "adding $file_path to be compressed [$dir_size]"
      zip -rq "$SHELL_UTILS_BACKUP_ZIP_FILE_PATH" "$file_path"
    elif [[ -f "$file_path" ]]; then
      file_size_output=$(du -h "$file_path")
      file_size=$(awk '{ print $1 }' <<<"$file_size_output")
      echo "adding $file_path to be compressed [$file_size]"
      zip -q "$SHELL_UTILS_BACKUP_ZIP_FILE_PATH" "$file_path"
    else
      echo "failed to add $file_path. It does not exist"
    fi
  done

  zip -T "$SHELL_UTILS_BACKUP_ZIP_FILE_PATH" >/dev/null
}

upload_backup_zip_to_rclone() {
  if [[ -z "$SHELL_UTILS_BACKUP_RCLONE_REMOTE" ]] && [[ -z "$SHELL_UTILS_BACKUP_RCLONE_FOLDER" ]]; then
    echo "rclone is not properly configured and the upload was not done." >&2
    return 0
  fi

  if ! command -v rclone >/dev/null; then
    _lib_fatal "remote copy failed: rclone not found. Ensure the zip is manually saved."
  fi

  if [[ ! -f "$SHELL_UTILS_BACKUP_ENCRYPTED_FILE_PATH" ]]; then
    echo "remote copy failed: backup must be encrypted to be uploaded. Enable encryption first."
    return 0
  fi

  echo -e "\nnow copying it to remote..."
  rclone copy -v "$SHELL_UTILS_BACKUP_ENCRYPTED_FILE_PATH" \
    "$SHELL_UTILS_BACKUP_RCLONE_REMOTE:$SHELL_UTILS_BACKUP_RCLONE_FOLDER"
}

encrypt_backup_zip() {
  local bypass_password="$1"

  if [[ "$bypass_password" = false ]]; then
    echo ""
    read -sr -p "confirm encryption password: " passw
    if [[ "$passw" != "$SHELL_UTILS_BACKUP_ENCRYPT_PASSWORD" ]]; then
      echo "predefined password and the current one typed do not match." >&2
      return 1
    fi
  fi

  openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt \
    -in "$SHELL_UTILS_BACKUP_ZIP_FILE_PATH" \
    -out "$SHELL_UTILS_BACKUP_ENCRYPTED_FILE_PATH" \
    -pass env:SHELL_UTILS_BACKUP_ENCRYPT_PASSWORD
}

main "$@"
