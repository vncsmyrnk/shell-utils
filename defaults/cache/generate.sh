#!/usr/bin/env bash

# [help]
# Generates a file listing all available commands available to the util command

SHELL_UTILS_CACHE_KEY_FILE="$(dirname "$SHELL_UTILS_CACHE_FILE")/key"

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

if [[ -f "$SHELL_UTILS_CACHE_FILE" ]] && ! "$force"; then
  cache_key=$(cat "$SHELL_UTILS_CACHE_KEY_FILE" 2>/dev/null || echo "")
  if [[ "$cache_key" == "$SHELL_UTILS_SCRIPTS" ]]; then
    exit 0
  fi
fi

mkdir -p "$(dirname "$SHELL_UTILS_CACHE_FILE")"
{
  fd --base-directory "$SHELL_UTILS_SCRIPTS" --format "$SHELL_UTILS_SCRIPTS":{} -E "_*" -E "help" -E "on-update"
  [ -d "$SHELL_UTILS_USER_SCRIPTS" ] &&
    fd --base-directory "$SHELL_UTILS_USER_SCRIPTS" --format "$SHELL_UTILS_USER_SCRIPTS":{} -E "_*" -E "help" -E "on-update"
} >"$SHELL_UTILS_CACHE_FILE"
echo "$SHELL_UTILS_SCRIPTS" >"$SHELL_UTILS_CACHE_KEY_FILE"
