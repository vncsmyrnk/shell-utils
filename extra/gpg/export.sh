#!/usr/bin/env bash

# [help]
# Exports the public and private gpg keys for an ID

SU_GPG_EXPORT_TARGET_PATH=${SU_GPG_EXPORT_TARGET_PATH:-/tmp}
SU_GPG_EXPORT_ENCRYPT_PASSWORD=${SU_GPG_EXPORT_ENCRYPT_PASSWORD-:}
SU_GPG_RCLONE_REMOTE=${SU_GPG_RCLONE_REMOTE:-}
SU_GPG_RCLONE_FOLDER=${SU_GPG_RCLONE_FOLDER:-}

remote=false
gpg_email=""

while [[ $# -gt 0 ]]; do
  case $1 in
  --remote)
    remote=true
    shift
    ;;
  -*)
    echo "Unknown option: $1"
    exit 1
    ;;
  *)
    if [[ -n "$gpg_email" ]]; then
      echo "Error: Multiple arguments provided."
      exit 1
    fi
    gpg_email="$1"
    shift
    ;;
  esac
done

if [ -z "$gpg_email" ]; then
  echo "Usage: util gpg export <gpg-email>"
  exit 1
fi

timestamp=$(date +"%Y%m%d%H%M%S")
private_key_target_path="$SU_GPG_EXPORT_TARGET_PATH/$gpg_email-private-key-backup.asc"
public_key_target_path="$SU_GPG_EXPORT_TARGET_PATH/$gpg_email-public-key-backup.asc"
trust_backup_target_path="$SU_GPG_EXPORT_TARGET_PATH/trust-backup.txt"
zipped_key_target_path="$SU_GPG_EXPORT_TARGET_PATH/$gpg_email-gpg-keys.zip"
encrypted_key_target_path="$SU_GPG_EXPORT_TARGET_PATH/$timestamp-$gpg_email-gpg-keys.enc"

export_gpg_key() {
  gpg --export-secret-keys --armor "$1" >"$private_key_target_path"
  gpg --export --armor "$1" >"$public_key_target_path"
  gpg --export-ownertrust >"$trust_backup_target_path"
}

zip_and_upload_key() {
  if [ -z "$SU_GPG_EXPORT_ENCRYPT_PASSWORD" ]; then
    printf "Define the \$SU_GPG_EXPORT_ENCRYPT_PASSWORD variable to properly encrypt the key compressed file."
    return 1
  fi

  if [ -z "$SU_GPG_RCLONE_REMOTE" ] || [ -z "$SU_GPG_RCLONE_FOLDER" ]; then
    printf "Define \$SU_GPG_RCLONE_REMOTE and \$SU_GPG_RCLONE_FOLDER variables to properly upload the key compressed file."
    return 1
  fi

  zip "$zipped_key_target_path" \
    "$private_key_target_path" \
    "$public_key_target_path" \
    "$trust_backup_target_path"

  openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt \
    -in "$zipped_key_target_path" \
    -out "$encrypted_key_target_path" \
    -pass env:SU_GPG_EXPORT_ENCRYPT_PASSWORD

  rclone copy -v "$encrypted_key_target_path" \
    "$SU_GPG_RCLONE_REMOTE:$SU_GPG_RCLONE_FOLDER"
}

main() {
  export_gpg_key "$gpg_email"

  if [ "$remote" = true ]; then
    zip_and_upload_key
  fi
}

main
