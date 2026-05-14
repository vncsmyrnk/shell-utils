#!/usr/bin/env bash

# [help]
# Restarts a currently running job
#
# Usage: util jobs restart [NAME]

# shellcheck source=extra/jobs/_variables
\. "./_variables"
: "${_jobs_session_name:=}"

job_name="$1"
if [[ -z "$job_name" ]]; then
  exit 1
fi

tmux respawn-pane -k -t "$_jobs_session_name":"$job_name"
