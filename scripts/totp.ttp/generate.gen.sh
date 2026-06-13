#!/usr/bin/env bash
set -e

# [help]
# Generates TOTP passwords based on predefined keys stored in gpg files
#
# The generated code is also copied to the clipboard via xclip.
#
# It expects the file name (entity) of the secret gpg file as an argument.
# The gpg files should be located at $TOTP_SECRETS_DIR which can be overriden
#
# The TOTP duration can be defined with $TOTP_CURRENT_TIME.
#
# Entities can be created with `$ util totp add`
#
# Usage: totp generate [ENTITY]

: "${SHELL_UTILS_SCRIPTS_PATH:=}"
# shellcheck source=scripts/_lib.sh
\. "${SHELL_UTILS_SCRIPTS_PATH}/_lib.sh"

: "${SHELL_UTILS_SCRIPT_DIRNAME:=}"
# shellcheck source=scripts/totp.ttp/_variables.sh
\. "${SHELL_UTILS_SCRIPT_DIRNAME}/_variables.sh"
: "${_totp_secrets_dir:=}"
: "${_totp_current_time:=}"

main() {
  local entity
  entity="$1"
  if [[ -z "$entity" ]]; then
    _lib_fatal "entity argument is required."
  fi

  if ! command -v oathtool &>/dev/null; then
    _lib_fatal "oath-toolkit is required for this script."
  fi

  local secret_file
  secret_file="$_totp_secrets_dir/$entity.gpg"
  if [[ ! -f "$secret_file" ]]; then
    _lib_fatal "secret not found for entity." >&2
  fi

  local totp_key
  totp_key=$(
    gpg -d -q "$secret_file"
  )

  local totp_code
  totp_code=$(
    oathtool --totp -b --now "$_totp_current_time" - <<<"$totp_key"
  )

  echo "$totp_code"
  if command -v wl-copy &>/dev/null; then
    echo -n "$totp_code" | wl-copy
  elif command -v xclip &>/dev/null; then
    echo -n "$totp_code" | xclip -selection clipboard
  fi
}

main "$@"
