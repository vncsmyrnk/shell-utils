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

TOTP_SECRETS_DIR=${SECRETS_DIR:-"$HOME/.secrets/totp"}
TOTP_CURRENT_TIME=${TOTP_CURRENT_TIME:-"5 seconds"}

error() {
  printf "$1\n"
  exit 1
}

usage() {
  printf "$1\n"
  echo "usage: totp generate [ENTITY]"
  exit 1
}

main() {
  entity="$1"
  if [[ -z "$entity" ]]; then
    usage "entity argument is required."
  fi

  if ! command -v oathtool &>/dev/null; then
    error "oath-toolkit is required for this script."
  fi

  secret_file="$TOTP_SECRETS_DIR/$entity.gpg"
  if [[ ! -f "$secret_file" ]]; then
    error "secret not found for entity.\n\nPlace them at \033[4m$TOTP_SECRETS_DIR\033[0m"
  fi

  totp_code=$(
    gpg -d -q "$secret_file" | oathtool --totp -b --now "$TOTP_CURRENT_TIME" -
  )

  echo "$totp_code"

  if command -v xclip &>/dev/null; then
    echo -n "$totp_code" | xclip -selection clipboard
  fi
}

main "$@"
