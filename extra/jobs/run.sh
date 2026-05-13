#!/usr/bin/env bash

# [help]
# Executes a command on a new window in the default session
#
# Usage: util jobs run <name> <command>

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=extra/jobs/_variables
\. "$DIR/_variables"
: "${_jobs_session_name:=}"

job_name="$1"
shift
job_task="$*"

if [[ -z "$job_task" ]]; then
  exit 1
fi

d=$(date +'%Y%m%d%H%M%S')
job_log_file="/tmp/$job_name.log"
instance_log_file="/tmp/$job_name-$d.log"

regex='^(([[:space:]]*trap[[:space:]]+"[^"]+"[[:space:]]+[A-Z]+;[[:space:]]*)+)(.*)'
if [[ "$job_task" =~ $regex ]]; then
  job_trap="${BASH_REMATCH[1]}"
  job_cmd="${BASH_REMATCH[3]}"
  job_exec="$job_trap ($job_cmd 2>&1) | tee \"$job_log_file\" \"$instance_log_file\""
else
  job_exec="($job_task 2>&1) | tee \"$job_log_file\" \"$instance_log_file\""
fi

if ! tmux list-windows -t "$_jobs_session_name" >/dev/null 2>&1; then
  tmux new-session -d -s "$_jobs_session_name" -n "$job_name" "$job_exec"
  exit 0
fi

tmux_windows=$(tmux list-windows -t "$_jobs_session_name" -F "#{m:$job_name,#{window_name}}")
grep -q 1 <<<"$tmux_windows"

tmux new-window -t "$_jobs_session_name" -n "$job_name" "$job_exec"
