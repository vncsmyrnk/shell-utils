#!/usr/bin/env bash
set -e

# [help]
# Exec a command setting sops secrets on the environment
#
# This allows the secrets to never be decrypted on physical drive.
#
# The default secret path is `$HOME/.config/shell-utils/environment/default.env` but it can be
# overriden with `-f|--file`.
#
# Usage: util environment exec <COMMAND> [OPTIONS]
#
# Options:
#  -f, --file [FILE]   Secret file
#
# Example: util environment exec -f /tmp/file.env gcloud project list

: "${SHELL_UTILS_SCRIPTS_PATH:=}"
# shellcheck source=scripts/_lib.sh
\. "${SHELL_UTILS_SCRIPTS_PATH}/_lib.sh"

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
  --)
    shift
    break
    ;;
  *)
    break
    ;;
  esac
done

exec_args="$*"
if [[ -z "$exec_args" ]]; then
  _lib_fatal "a command is required."
fi

sops exec-env "$secrets_path" "$exec_args"
