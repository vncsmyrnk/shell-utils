#!/usr/bin/env bash
set -e

# [help]
# Executes a command on a new window in the default session
#
# Usage: util jobs run [NAME] [COMMAND]

: "${SHELL_UTILS_SCRIPT_DIRNAME:=}"
# shellcheck source=scripts/jobs/_variables.sh
\. "${SHELL_UTILS_SCRIPT_DIRNAME}/_variables.sh"

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

: "${_jobs_session_name:=}"
if ! tmux list-windows -t "$_jobs_session_name" >/dev/null 2>&1; then
  tmux new-session -d -s "$_jobs_session_name" -n "$job_name" "$job_exec"
  exit 0
fi

tmux_windows=$(tmux list-windows -t "$_jobs_session_name" -F "#{m:$job_name,#{window_name}}")
grep -q 1 <<<"$tmux_windows"

tmux new-window -t "$_jobs_session_name" -n "$job_name" "$job_exec"
