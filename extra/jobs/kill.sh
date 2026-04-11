#!/usr/bin/env bash

# [help]
# Kill running jobs

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
\. "$DIR/_variables"

job_name="$1"
if [[ -z "$job_name" ]]; then
  if [[ " $* " == *" --all "* ]]; then
    tmux kill-session -t "$SESSION_NAME"
  fi
  exit 1
fi

tmux kill-window -t "$SESSION_NAME":"$job_name"
