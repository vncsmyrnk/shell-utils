#!/usr/bin/env bash

# [help]
# Cryptographs TOTP keys on gpg files to be later used to generate TOTP passwords
#
# The key is stored as an entity. TOTP passwords can be generated with `$ util totp generate <entity>`

TOTP_SECRETS_DIR=${TOTP_SECRETS_DIR:-"$HOME/.secrets/totp"}
KEY_TMP_PATH=/tmp/key

help() {
  echo "Usage: totp add <entity-name> <key>"
}

if [[ -z "$2" ]]; then
  help
  exit 0
fi

entity="$1"
key="$2"

entity_path="$TOTP_SECRETS_DIR/${entity}.gpg"
if [[ -f "$entity_path" ]]; then
  echo -n "An entity with this name already exists. Override it? [y/N]: "
  read -r choice
  if [ "$choice" != "y" ] && [ "$choice" != "Y" ]; then
    exit 0
  fi
fi

rm -f "$KEY_TMP_PATH"
echo "$key" >"$KEY_TMP_PATH"
gpg -c "$KEY_TMP_PATH"
mv "$KEY_TMP_PATH.gpg" "$entity_path"
rm -f "$KEY_TMP_PATH"
