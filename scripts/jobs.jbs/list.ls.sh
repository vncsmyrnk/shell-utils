#!/usr/bin/env bash
set -e

# [help]
# List all running jobs
#
# Usage: util jobs list

: "${SHELL_UTILS_SCRIPT_DIRNAME:=}"
# shellcheck source=scripts/jobs.jbs/_variables.sh
\. "${SHELL_UTILS_SCRIPT_DIRNAME}/_variables.sh"

: "${_jobs_session_name:=}"

if ! tmux list-windows -t "$_jobs_session_name" -F "#{window_name}" 2>/dev/null; then
  echo "no active jobs found." >&2
  exit 1
fi
