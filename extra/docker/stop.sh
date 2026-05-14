#!/usr/bin/env bash

# [help]
# Stops docker containers

# shellcheck source=extra/_lib.sh
\. "./../_lib.sh"

# shellcheck source=extra/_error.sh
\. "./../_error.sh"

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
