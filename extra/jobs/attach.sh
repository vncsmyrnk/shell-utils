#!/usr/bin/env bash

# [help]
# Attaches to the tmux session and window of a job
#
# Usage: util jobs attach [NAME]

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=extra/jobs/_variables
\. "$DIR/_variables"
: "${_jobs_session_name:=}"

job_name="$1"
if [[ -z "$job_name" ]]; then
  exit 1
fi

tmux switch-client -t "$_jobs_session_name:$job_name"
