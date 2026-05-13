#!/usr/bin/env bash

# [help]
# Exec a command setting sops secrets on the environment
#
# This allows the secrets to never be decrypted on physical drive.
#
# If no argument is specified, a new shell is launched with the provided secrets.
#
# The default secret path is `$HOME/.secrets/sops/secrets.env` but it can be
# overriden with `-f|--file`.
#
# Usage: util environment exec [OPTIONS] [COMMAND]
#
# Options:
#  -f, --file [FILE]   Secret file
#
# Example: util environment exec -f /tmp/file.env gcloud project list

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=extra/environment/_variables
\. "$DIR/_variables"
: "${_secrets_path:=}"

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

exec_args="$*"
if [[ -z "$exec_args" ]]; then
  exec_args="$SHELL"
fi

sops exec-env "$secrets_path" "$exec_args"
