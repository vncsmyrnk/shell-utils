#!/usr/bin/env bash

# [help]
# Pages the job standard output
#
# Usage: util jobs logs <name>

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
\. "$DIR/_variables"

_pager=${PAGER:-vim}

job_name="$1"
log_file=$(
  find "$_jobs_log_dir" -type f -name "$job_name-*.log" -printf '%T@ %p\0' 2>/dev/null |
    sort -z -n | tail -z -n 1 | sed -z 's/^[^ ]* //' | tr -d '\0'
)
if [[ -z "$log_file" ]]; then
  exit 1
fi

if [[ " $* " == *" -f "* ]]; then
  tail -f "$log_file"
  exit 0
fi
command $_pager "$log_file"
