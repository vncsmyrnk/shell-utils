#!/usr/bin/env bash

# [help]
# Generates random hex based pseudo-random strings using openssl
#
# Usage: util random generate
#
# Options:
#  -l, --length   Length of the random string being generated (default: 10)

# shellcheck source=extra/_lib.sh
\. "./../_lib.sh"

# shellcheck source=extra/_error.sh
\. "./../_error.sh"
if ! command -v openssl >/dev/null; then
  exit 1
fi

length=10
while [[ $# -gt 0 ]]; do
  case $1 in
  -l | --length)
    length="$2"
    shift 2
    ;;
  --length=*)
    length="${1#*=}"
    shift
    ;;
  *)
    break
    ;;
  esac
done

bytes=$((("$length" / 2) + 1))
random_string=$(openssl rand -hex "$bytes")
echo "${random_string:0:$length}"
