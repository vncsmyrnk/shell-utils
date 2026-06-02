#!/usr/bin/env bash
set -e

# [help]
# Clears docker build and volume cache

docker builder prune
docker volume prune
