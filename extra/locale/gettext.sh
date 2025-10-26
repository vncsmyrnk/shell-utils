#!/bin/sh

# [help]
# Fetches a corresponding translation of a word in a mo file.
#
# Usage: `util locale gettext [FILE] [ID] [-l language]`

# [completions]
# -l[forces language instead of infering it from the mo path]

while getopts ":l" opt; do
  case $opt in
  l) language="$OPTARG" ;;
  \?) echo "Invalid option -$OPTARG" >&2 ;;
  esac
done

path_to_mo_file="$1"
message_id="$2"

if [ -z "$path_to_mo_file" ] || [ -z "$message_id" ]; then
  echo "usage: <path_to_mo_file> <message_id> -l <LANGUAGE>"
  exit 1
fi

path_to_mo_file="$(realpath $path_to_mo_file)"
if [ ! -f $path_to_mo_file ]; then
  printf "file not found\n" >&2
  exit 1
fi

dir_to_domain="$(dirname "$(dirname "$(dirname "$path_to_mo_file")")")"
domain="$(basename "$path_to_mo_file" .mo)"

if [ -z "$language" ]; then
  language=$(basename "$(dirname "$(dirname "$path_to_mo_file")")")
fi

LANGUAGE="$language" TEXTDOMAIN="$domain" TEXTDOMAINDIR="$dir_to_domain" gettext "$message_id"
