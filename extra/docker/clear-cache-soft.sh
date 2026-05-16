#!/usr/bin/env bash

# [help]
# Clears docker build and volume cache

# shellcheck source=extra/_error.sh
if ! e=$(util-fetch "$(realpath "./../_error.sh" || true)"); then
  exit 1
fi
\. <(echo "$e")

docker builder prune
docker volume prune
