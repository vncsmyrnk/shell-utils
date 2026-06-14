#!/usr/bin/env bash
set -e

# [help]
# Edits the sops secrets variables using $EDITOR
#
# The default secret path is `$HOME/.config/shell-utils/environment/default.env` but it can be
# overriden with `-f|--file`.
#
# Usage: util environments edit [OPTIONS]
#
# Options:
#  -f, --file [FILE]   Secret file

: "${SHELL_UTILS_SCRIPT_DIRNAME:=}"
# shellcheck source=scripts/environment.env/_variables.sh
\. "${SHELL_UTILS_SCRIPT_DIRNAME}/_variables.sh"

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
