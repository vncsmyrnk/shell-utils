#!/usr/bin/env bash

# [help]
# List all running jobs

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
\. "$DIR/_variables"

tmux list-windows -t "$SESSION_NAME" -F "#{window_name}" 2>/dev/null
