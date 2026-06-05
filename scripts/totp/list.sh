#!/usr/bin/env bash
set -e

# [help]
# List available TOTP entities
#
# Usage: totp list

: "${SHELL_UTILS_SCRIPT_DIRNAME:=}"
# shellcheck source=scripts/totp/_variables.sh
\. "${SHELL_UTILS_SCRIPT_DIRNAME}/_lib.sh"

: "${SHELL_UTILS_SCRIPTS_PATH:=}"
# shellcheck source=scripts/_lib.sh
\. "${SHELL_UTILS_SCRIPTS_PATH}/_lib.sh"
: "${_totp_secrets_dir:=}"

while read -r file; do
  _lib_files_filename_noext "$file"
done < <(
  find "$_totp_secrets_dir" \
    -maxdepth 1 \
    -type f \
    -printf '%f\n' || true
)
