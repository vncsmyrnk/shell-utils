#!/usr/bin/env bash

# [help]
# Generates random hex based pseudo-random strings using openssl

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
random_string=$(openssl rand -hex "$bytes" 2>/dev/null || echo -n "")
output="${random_string:0:$length}"
if [[ -z "$output" ]]; then
  echo "failed to generate random string using openssl"
  exit 1
fi
echo "$output"
