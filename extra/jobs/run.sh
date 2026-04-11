#!/usr/bin/env bash

# [help]
# Executes a command on a new window in the default session

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
\. "$DIR/_variables"

job_name="$1"
shift
job_task="$*"

if [[ -z "$job_task" ]]; then
  exit 1
fi

if ! tmux list-windows -t "$SESSION_NAME" >/dev/null 2>&1; then
  tmux new-session -d -s "$SESSION_NAME" -n "$job_name" "$job_task"
  exit 0
fi

if tmux list-windows -t "$SESSION_NAME" -F "#{m:$job_name,#{window_name}}" | grep -q 1; then
  exit 1
fi

tmux new-window -t "$SESSION_NAME" -n "$job_name" "$job_task"
