#!/usr/bin/env bash

# [help]
# Kill running jobs
#
# Usage: util jobs kill <name>

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
\. "$DIR/_variables"

if [[ " $* " == *" --all "* ]]; then
  tmux kill-session -t "$_jobs_session_name"
fi

job_name="$1"
if [[ -z "$job_name" ]]; then
  exit 1
fi

tmux kill-window -t "$_jobs_session_name":"$job_name"
