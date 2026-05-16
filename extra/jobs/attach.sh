#!/usr/bin/env bash

# [help]
# Attaches to the tmux session and window of a job
#
# Usage: util jobs attach [NAME]

# shellcheck source=extra/jobs/_variables
if ! e=$(util-fetch "$(realpath "./_variables" || true)"); then
  exit 1
fi
\. <(echo "$e")

: "${_jobs_session_name:=}"

job_name="$1"
if [[ -z "$job_name" ]]; then
  exit 1
fi

tmux switch-client -t "$_jobs_session_name:$job_name"
