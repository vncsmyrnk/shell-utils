#!/usr/bin/env bash
set -e

# [help]
# Attaches to the tmux session and window of a job
#
# Usage: util jobs attach [NAME]

: "${SHELL_UTILS_SCRIPT_DIRNAME:=}"
# shellcheck source=scripts/jobs/_variables.sh
\. "${SHELL_UTILS_SCRIPT_DIRNAME}/_variables.sh"

job_name="$1"
if [[ -z "$job_name" ]]; then
  exit 1
fi

: "${_jobs_session_name:=}"
tmux switch-client -t "$_jobs_session_name:$job_name"
