#!/usr/bin/env bash

# [help]
# Stops docker containers

if ! command -v ifne >/dev/null; then
  echo "The \`moreutils\` is necessary for this script to work properly."
  exit 1
fi

if [[ " $* " == *" --all "* ]]; then
  docker ps |
    awk 'NR!=1 { print $1 }' |
    ifne xargs docker stop
  exit 0
fi

if [[ -z "$1" ]]; then
  echo "An ID or \`-all\` is required."
  exit 1
fi

docker stop "$1"
