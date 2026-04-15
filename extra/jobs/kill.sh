#!/usr/bin/env bash

# [help]
# Kill running jobs
#
# Usage: util jobs kill <name> [--all]

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
\. "$DIR/_variables"

if [[ " $* " == *" --all "* ]]; then
  tmux list-panes -s -t "$_jobs_session_name" -F '#{pane_id}' |
    xargs -I {} tmux send-keys -t {} C-c
  exit 0
fi

job_name="$1"
if [[ -z "$job_name" ]]; then
  exit 1
fi

tmux list-panes -t "$_jobs_session_name":"$job_name" -F '#{pane_id}' |
  xargs -I {} tmux send-keys -t {} C-c
