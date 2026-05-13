#!/usr/bin/env bash

# [help]
# Edits the sops secrets variables using $EDITOR
#
# The default secret path is `$HOME/.secrets/sops/secrets.env` but it can be
# overriden with `-f|--file`.
#
# Usage: util environments edit [OPTIONS]
#
# Options:
#  -f, --file [FILE]   Secret file

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=extra/workspaces/_variables.sh
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

sops "$secrets_path"
