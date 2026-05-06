#!/usr/bin/env bash

# [help]
# Exec a command setting sops secrets on the environent
#
# This allows the secrets to never be decrypted on physical drive.
#
# The default secret path is `$HOME/.secrets/sops/secrets.env` but it can be
# overriden with `-f|--file`.
#
# Usage: util sops exec-env [-f file] <command>

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
\. "$DIR/_variables"

secrets_path="$_secrets_path"

while [[ $# -gt 0 ]]; do
  case $1 in
  -f | --file)
    secrets_path="$2"
    shift 2
    ;;
  *)
    break
    ;;
  esac
done

sops exec-env "$secrets_path" "$*"
