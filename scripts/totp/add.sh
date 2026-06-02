#!/usr/bin/env bash
set -e

# [help]
# Cryptographs TOTP keys on gpg files to be later used to generate TOTP passwords
#
# The key is stored as an entity. TOTP passwords can be generated with `$ util totp generate <entity>`
#
# Usage: totp add [ENTITY] < input.txt
#
# Example: u totp add github < /path/to/key

: "${SHELL_UTILS_SCRIPTS_PATH:=}"
# shellcheck source=scripts/_lib.sh
\. "${SHELL_UTILS_SCRIPTS_PATH}/_lib.sh"

TOTP_SECRETS_DIR=${TOTP_SECRETS_DIR:-"$HOME/.secrets/totp"}
KEY_TMP_PATH=/tmp/key

entity="$1"
if [[ -z "$entity" ]]; then
  _lib_fatal "an entity must be provided."
fi

key=$(cat)
if [[ -z "$key" ]]; then
  _lib_fatal "key must be provided via STDIN."
fi

entity_path="$TOTP_SECRETS_DIR/${entity}.gpg"
if [[ -f "$entity_path" ]]; then
  echo -n "An entity with this name already exists. Override it? [y/N]: "
  read -r response </dev/tty
  if [[ ! $response =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

secret_path="$KEY_TMP_PATH.gpg"
rm -f "$KEY_TMP_PATH" "$secret_path"

echo "$key" >"$KEY_TMP_PATH"
if ! gpg -c "$KEY_TMP_PATH"; then
  rm -rf "$KEY_TMP_PATH"
fi

if ! mv "$secret_path" "$entity_path"; then
  rm -rf "$KEY_TMP_PATH"
fi
