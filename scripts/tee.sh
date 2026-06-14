#!/usr/bin/env bash
set -e

# [help]
# Tee's STDIN to a temporary file

out=$(mktemp)
tee "$out"
