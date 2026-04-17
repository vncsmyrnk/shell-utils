#!/usr/bin/env bash

# [help]
# Executes a command on a new window in the default session
#
# Usage: util jobs run <name> <command>

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
\. "$DIR/_variables"

job_name="$1"
shift
job_task="$*"

if [[ -z "$job_task" ]]; then
  exit 1
fi

d=$(date +'%Y%m%d%H%M%S')
if ! tmux list-windows -t "$_jobs_session_name" >/dev/null 2>&1; then
  tmux new-session -d -s "$_jobs_session_name" -n "$job_name" "($job_task 2>&1) | tee /tmp/$job_name-$d.log"
  exit 0
fi

if tmux list-windows -t "$_jobs_session_name" -F "#{m:$job_name,#{window_name}}" | grep -q 1; then
  exit 1
fi

tmux new-window -t "$_jobs_session_name" -n "$job_name" "($job_task 2>&1) | tee /tmp/$job_name-$d.log"
