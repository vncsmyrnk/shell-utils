#!/usr/bin/env bash

# [help]
# List all running jobs
#
# Usage: util jobs list

# shellcheck source=extra/jobs/_variables
\. "./_variables"
: "${_jobs_session_name:=}"

tmux list-windows -t "$_jobs_session_name" -F "#{window_name}" 2>/dev/null
