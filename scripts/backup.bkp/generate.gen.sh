#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

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

: "${SHELL_UTILS_SCRIPT_DIRNAME:=}"
# shellcheck source=scripts/backup.bkp/_variables.sh
\. "${SHELL_UTILS_SCRIPT_DIRNAME}/_variables.sh"

: "${_backup_paths:=}"
: "${_backup_zip_dir:=}"
: "${_backup_encrypted_dir:=}"
: "${_backup_encrypt_password:=}"
: "${_backup_rclone_remote:=}"
: "${_backup_rclone_folder:=}"
: "${_backup_zip_file_path:=}"
: "${_backup_encrypted_file_path:=}"

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

main() {
  if [[ -z "$_backup_encrypt_password" ]]; then
    echo "encrypt password was not provided." >&2
    return 1
  fi

  # shellcheck disable=SC2310
  if ! compress_files; then
    return 1
  fi

  backup_size_output=$(du -h "$_backup_zip_file_path")
  backup_size=$(awk '{ print $1 }' <<<"$backup_size_output")
  echo "backup file generated at $_backup_zip_file_path [$backup_size]"

  # shellcheck disable=SC2310
  if ! encrypt_backup_zip "$bypass_password"; then
    return 1
  fi

  # shellcheck disable=SC2310
  if ! upload_backup_zip_to_rclone; then
    return 1
  fi
  echo -e "\nbackup successfuly done."
}

compress_files() {
  local file_path
  local dir_size
  local file_size
  local size_output
  local -a backup_paths
  local IFS=' '
  read -r -a backup_paths <<<"$_backup_paths"

  for file_path in "${backup_paths[@]}"; do
    if [[ -d "$file_path" ]]; then
      size_output=$(du -shL "$file_path")
      IFS=$'\t' read -r dir_size _ <<<"$size_output"
      echo "adding $file_path to be compressed [$dir_size]"
      zip -rq "$_backup_zip_file_path" "$file_path"
    elif [[ -f "$file_path" ]]; then
      size_output=$(du -h "$file_path")
      IFS=$'\t' read -r file_size _ <<<"$size_output"
      echo "adding $file_path to be compressed [$file_size]"
      zip -q "$_backup_zip_file_path" "$file_path"
    else
      echo "failed to add $file_path. It does not exist"
    fi
  done

  zip -T "$_backup_zip_file_path" >/dev/null
}

upload_backup_zip_to_rclone() {
  if [[ -z "$_backup_rclone_remote" ]] && [[ -z "$_backup_rclone_folder" ]]; then
    echo "rclone is not properly configured and the upload was not done." >&2
    return 0
  fi

  if ! command -v rclone >/dev/null 2>&1; then
    _lib_fatal "remote copy failed: rclone not found. Ensure the zip is manually saved."
  fi

  if [[ ! -f "$_backup_encrypted_file_path" ]]; then
    echo "remote copy failed: backup must be encrypted to be uploaded. Enable encryption first."
    return 0
  fi

  echo -e "\nnow copying it to remote..."
  rclone copy -v "$_backup_encrypted_file_path" \
    "$_backup_rclone_remote:$_backup_rclone_folder"
}

encrypt_backup_zip() {
  local bypass_password="$1"

  if [[ "$bypass_password" = false ]]; then
    echo ""
    read -sr -p "confirm encryption password: " passw
    if [[ "$passw" != "$_backup_encrypt_password" ]]; then
      echo "predefined password and the current one typed do not match." >&2
      return 1
    fi
  fi

  openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt \
    -in "$_backup_zip_file_path" \
    -out "$_backup_encrypted_file_path" \
    -pass env:SHELL_UTILS_BACKUP_ENCRYPT_PASSWORD
}

main "$@"
