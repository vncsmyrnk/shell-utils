#!/usr/bin/env bash

# [help]
# Pages the job standard output
#
# Usage: util jobs log <name>

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=extra/jobs/_variables
\. "$DIR/_variables"
: "${_jobs_log_dir:=}"

_pager=${PAGER:-vim}

job_name="$1"
log_file="$_jobs_log_dir/$job_name.log"
if [[ -z "$log_file" ]]; then
  exit 1
fi

if [[ " $* " == *" -f "* ]]; then
  tail -f "$log_file"
  exit 0
fi
command $_pager "$log_file"
