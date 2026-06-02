#!/usr/bin/env bash
set -e

# [help]
# Copies the second and first lines of a pass password one after the other
#
# This is useful when storing the username and password as the second and first lines
# of a pass password to use them on the login page.
#
# Usage: util pass cp2l
#
# Options:
#  -t, --first-copy-timeout   Time waited after the user is copied before
#                             copying the password to the clipboard

: "${SHELL_UTILS_SCRIPTS_PATH:=}"
# shellcheck source=scripts/_lib.sh
\. "${SHELL_UTILS_SCRIPTS_PATH}/_lib.sh"

first_copy_timeout=1
while [[ $# -gt 0 ]]; do
  case $1 in
  -t | --first-copy-timeout)
    first_copy_timeout="$2"
    shift 2
    ;;
  --first-copy-timeout=*)
    first_copy_timeout="${1#*=}"
    shift
    ;;
  *)
    break
    ;;
  esac
done

if [[ -z "$1" ]]; then
  _lib_fatal "an entity is required"
fi

pass -c2 "$1" >/dev/null

{
  sleep "$first_copy_timeout"
  pass -c "$1" >/dev/null
} &
