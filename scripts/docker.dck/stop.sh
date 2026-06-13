#!/usr/bin/env bash
set -e

# [help]
# Stops docker containers

: "${SHELL_UTILS_SCRIPT_DIRNAME:=}"
# shellcheck source=scripts/_lib.sh
\. "${SHELL_UTILS_SCRIPT_DIRNAME}/_lib.sh"

if [[ " $* " == *" --all "* ]]; then
  container_ids=$(docker ps -q)
  if [[ -z "$container_ids" ]]; then
    _lib_fatal "no container is running."
  fi
  xargs -P 5 docker stop <<<"$container_ids"
  exit 0
fi

if [[ -z "$1" ]]; then
  _lib_fatal "an ID or \`-all\` is required."
fi

docker stop "$1"
