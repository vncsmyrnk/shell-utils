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

follow=false
job_name=
while [[ $# -gt 0 ]]; do
  case $1 in
  -f | --follow)
    follow=true
    shift
    ;;
  *)
    if [[ -n "$job_name" ]]; then
      echo "Unexpected extra argument \"$1\""
      break
    fi
    job_name="$1"
    shift
    ;;
  esac
done

if [[ -z "$job_name" ]]; then
  echo "A job name is required." >&2
  exit 1
fi

: "${_jobs_log_dir:=}"
log_file="$_jobs_log_dir/$job_name.log"
if [[ ! -f "$log_file" ]]; then
  echo "job not found." >&2
  exit 1
fi

if [[ "$follow" = "true" ]]; then
  tail -f "$log_file"
  exit 0
fi

_pager=${PAGER:-vim}
command $_pager "$log_file"
