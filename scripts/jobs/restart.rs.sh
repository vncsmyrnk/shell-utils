#!/usr/bin/env bash
set -e

# [help]
# Restarts a currently running job
#
# Usage: util jobs restart [NAME]

: "${SHELL_UTILS_SCRIPT_DIRNAME:=}"
# shellcheck source=scripts/jobs/_variables.sh
\. "${SHELL_UTILS_SCRIPT_DIRNAME}/_variables.sh"

job_name="$1"
if [[ -z "$job_name" ]]; then
  exit 1
fi

: "${_jobs_session_name:=}"
tmux respawn-pane -k -t "$_jobs_session_name":"$job_name"
