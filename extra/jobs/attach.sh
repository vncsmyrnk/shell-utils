#!/usr/bin/env bash

# [help]
# Attaches to the TMUX session and window of a job
#
# Usage: util jobs attach <name>

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
\. "$DIR/_variables"

job_name="$1"
if [[ -z "$job_name" ]]; then
  exit 1
fi

tmux switch-client -t "$_jobs_session_name:$job_name"
