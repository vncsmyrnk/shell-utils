#!/usr/bin/env bash

# [help]
# List all running jobs
#
# Usage: util jobs list [--all]

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=extra/jobs/_variables
\. "$DIR/_variables"
: "${_jobs_session_name:=}"

tmux list-windows -t "$_jobs_session_name" -F "#{window_name}" 2>/dev/null
