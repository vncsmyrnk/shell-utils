#!/usr/bin/env bash

# [help]
# Clears docker build and volume cache

# shellcheck source=extra/_error.sh
\. "./../_error.sh"

docker builder prune
docker volume prune
