#!/usr/bin/env bash

# [help]
# Clears docker build and volume cache

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=extra/_error.sh
\. "$DIR/../_error.sh"

docker builder prune
docker volume prune
