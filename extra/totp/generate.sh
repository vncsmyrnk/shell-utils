#!/usr/bin/env bash

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

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=extra/_lib.sh
\. "$DIR/../_lib.sh"

# shellcheck source=extra/_error.sh
\. "$DIR/../_error.sh"

TOTP_SECRETS_DIR=${TOTP_SECRETS_DIR:-"$HOME/.secrets/totp"}
TOTP_CURRENT_TIME=${TOTP_CURRENT_TIME:-"5 seconds"}

error() {
  echo -e "$1" >&2
  exit 1
}

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
  secret_file="$TOTP_SECRETS_DIR/$entity.gpg"
  if [[ ! -f "$secret_file" ]]; then
    _lib_fatal "secret not found for entity.\n\nPlace them at \033[4m$TOTP_SECRETS_DIR\033[0m" >&2
  fi

  local totp_key
  totp_key=$(
    gpg -d -q "$secret_file"
  )

  local totp_code
  totp_code=$(
    oathtool --totp -b --now "$TOTP_CURRENT_TIME" - <<<"$totp_key"
  )

  echo "$totp_code"
  if command -v wl-copy &>/dev/null; then
    echo -n "$totp_code" | wl-copy
  elif command -v xclip &>/dev/null; then
    echo -n "$totp_code" | xclip -selection clipboard
  fi
}

main "$@"
