#!/usr/bin/env bash
set -e

# [help]
# Kill running jobs
#
# Usage: util jobs kill [NAME] [OPTIONS]
#
# Options:
#  --all   Kill all jobs

: "${SHELL_UTILS_SCRIPTS_PATH:=}"
# shellcheck source=scripts/_lib.sh
\. "${SHELL_UTILS_SCRIPTS_PATH}/_lib.sh"

: "${SHELL_UTILS_SCRIPT_DIRNAME:=}"
# shellcheck source=scripts/jobs.jbs/_variables.sh
\. "${SHELL_UTILS_SCRIPT_DIRNAME}/_variables.sh"

: "${_jobs_session_name:=}"

tmux_kill_pane_ids() {
  xargs -I{} tmux send-keys -t {} C-c <<<"$@"
}

if [[ " $* " == *" --all "* ]]; then
  pane_ids=$(
    tmux list-panes -s -t "$_jobs_session_name" -F '#{pane_id}'
  )
  tmux_kill_pane_ids "${pane_ids[@]}"
  exit 0
fi

job_name="$1"
if [[ -z "$job_name" ]]; then
  _lib_fatal "a job name is required."
fi

pane_ids=$(
  tmux list-panes -t "$_jobs_session_name":"$job_name" -F '#{pane_id}'
)
tmux_kill_pane_ids "${pane_ids[@]}"
