#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# [help]
# Downloads a backup file, decrypts and unzips it
#
# Usage: util backup remote unwrap [OPTIONS] [FILE]
#
# Options:
#  -l, --latest   Fetch the latest backup available
#
# Tip: use `rsync -av backup dest` to copy the backup files to their destination places

: "${SHELL_UTILS_SCRIPTS_PATH:=}"
# shellcheck source=scripts/_lib.sh
\. "${SHELL_UTILS_SCRIPTS_PATH}/_lib.sh"

: "${SHELL_UTILS_SCRIPT_DIRNAME:=}"
# shellcheck source=scripts/backup.bkp/_variables.sh
\. "${SHELL_UTILS_SCRIPT_DIRNAME}/../_variables.sh"

: "${_backup_encrypt_password:=}"
: "${_backup_rclone_remote:=}"
: "${_backup_rclone_folder:=}"
: "${_backup_remote_unwrap_dest:=}"

latest_flag=false
while [[ $# -gt 0 ]]; do
  case $1 in
  -l | --latest)
    latest_flag=true
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

check_dependencies() {
  if ! command -v rclone >/dev/null 2>&1; then
    _lib_fatal "dependencies: rclone not found."
  fi
}

decrypt_backup() {
  local encrypted_file="$1"
  local dest_decrypted_file
  local dest_backup_file
  local dest_decrypted_file_noext

  dest_encrypted_file_basename=$(basename "$encrypted_file")
  dest_decrypted_file_noext=$(cut -d '.' -f1 <<<"$dest_encrypted_file_basename")
  dest_decrypted_file="$dest_decrypted_file_noext.$(cut -d '.' -f2 <<<"$dest_encrypted_file_basename")"
  dest_backup_file="$_backup_remote_unwrap_dest/$dest_decrypted_file"

  openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -salt \
    -in "$encrypted_file" \
    -out "$dest_backup_file" \
    -pass env:SHELL_UTILS_BACKUP_ENCRYPT_PASSWORD

  unzip -q "$dest_backup_file" -d "$_backup_remote_unwrap_dest/$dest_decrypted_file_noext"
}

main() {
  local backup_file=""
  local files
  local last_file_output

  check_dependencies

  if [[ $# -gt 1 ]]; then
    _lib_fatal "A backup file must be the only positional argument."
  fi

  if [[ -z "$_backup_encrypt_password" ]]; then
    _lib_fatal "unwrap failed: no password was provided"
  fi

  if [[ $# -eq 1 ]] && [[ "$latest_flag" = true ]]; then
    _lib_fatal "invalid options. The \033[1m--latest\033[0m implies no other arguments\n"
  elif [[ $# -eq 0 ]] && [[ "$latest_flag" = false ]]; then
    _lib_fatal "A backup file must be informed."
  fi

  if [[ $# -eq 1 ]]; then
    backup_file="$1"
  fi
  if [[ "$latest_flag" = true ]]; then
    echo "Fetching latest backup file..."
    files=$(rclone ls "$_backup_rclone_remote:$_backup_rclone_folder")
    last_file_output=$(head -n 1 <<<"$files")
    backup_file=$(awk '{ print $1 }' <<<"$last_file_output")
  fi

  echo "Downloading backup file..."
  rclone copy "$_backup_rclone_remote:$_backup_rclone_folder/$backup_file" \
    "$_backup_remote_unwrap_dest"

  echo "Decrypting it..."
  decrypt_backup "$_backup_remote_unwrap_dest/$backup_file"

  echo "Done. Backup unwrapped at $_backup_remote_unwrap_dest"
}

main "$@"
