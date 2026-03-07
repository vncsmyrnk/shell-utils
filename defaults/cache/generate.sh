#!/usr/bin/env bash

# [help]
# Generates a file listing all available commands available to the util command

force=false
while [ $# -gt 0 ]; do
  case $1 in
  -f | --force)
    force=true
    shift
    ;;
  *)
    shift
    ;;
  esac
done

if [ -f "$SHELL_UTILS_CACHE_FILE" ] && ! "$force"; then
  # Cache file is always created at runtime
  exit 0
fi

mkdir -p "$(dirname "$SHELL_UTILS_CACHE_FILE")"
{
  fd --base-directory "$SHELL_UTILS_SCRIPTS" --format "$SHELL_UTILS_SCRIPTS":{} -E "_*" -E "help" -E "on-update"
  [ -d "$SHELL_UTILS_USER_SCRIPTS" ] &&
    fd --base-directory "$SHELL_UTILS_USER_SCRIPTS" --format "$SHELL_UTILS_USER_SCRIPTS":{} -E "_*" -E "help" -E "on-update"
} >"$SHELL_UTILS_CACHE_FILE"
