#!/usr/bin/env bash

# [help]
# Copies the second and first lines of a pass password one after the other
#
# This is useful when storing the username and password as the second and first lines
# of a pass password to use them on the login page.

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
  printf "usage: util pass cp2l <pass-name>\n"
  exit 1
fi

main() {
  pass -c2 "$1" >/dev/null || exit 1
  {
    sleep "$first_copy_timeout"
    pass -c "$1" >/dev/null
  } &
}

main "$@"
