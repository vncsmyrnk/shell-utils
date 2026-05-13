#!/usr/bin/env bash

# [help]
# Fetches a corresponding translation of a word in a mo file.
#
# Usage: `util locale gettext [FILE] [ID] [-l language]`

language=""
while [[ $# -gt 0 ]]; do
  case $1 in
  -l | --language)
    language="$2"
    shift 2
    ;;
  *)
    break
    ;;
  esac
done

path_to_mo_file="$1"
message_id="$2"
if [[ -z "$message_id" ]]; then
  echo "path to MO file and message ID are required." >&2
  exit 1
fi

path_to_mo_file="$(realpath "$path_to_mo_file")"
if [[ ! -f "$path_to_mo_file" ]]; then
  echo "file not found." >&2
  exit 1
fi

dir_to_domain="$(dirname "$(dirname "$(dirname "$path_to_mo_file")")")"
domain="$(basename "$path_to_mo_file" .mo)"

if [[ -z "$language" ]]; then
  language=$(basename "$(dirname "$(dirname "$path_to_mo_file")")")
fi

LANGUAGE="$language" TEXTDOMAIN="$domain" TEXTDOMAINDIR="$dir_to_domain" gettext "$message_id"
