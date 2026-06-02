#!/usr/bin/env bash
set -e

# [help]
# Pages the job standard output
#
# Usage: util jobs log [NAME] [OPTIONS]
#
# Options
#  -f   Follow output on the current prompt

: "${SHELL_UTILS_SCRIPT_DIRNAME:=}"
# shellcheck source=scripts/jobs/_variables.sh
\. "${SHELL_UTILS_SCRIPT_DIRNAME}/_variables.sh"

job_name="$1"
: "${_jobs_log_dir:=}"
log_file="$_jobs_log_dir/$job_name.log"
if [[ -z "$log_file" ]]; then
  exit 1
fi

if [[ " $* " == *" -f "* ]]; then
  tail -f "$log_file"
  exit 0
fi

_pager=${PAGER:-vim}
command $_pager "$log_file"
