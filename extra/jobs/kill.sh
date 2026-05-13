#!/usr/bin/env bash

# [help]
# Kill running jobs
#
# Usage: util jobs kill <name> [--all]

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=extra/_lib.sh
\. "$DIR/../_lib.sh"

# shellcheck source=extra/_error.sh
\. "$DIR/../_error.sh"

# shellcheck source=extra/jobs/_variables
\. "$DIR/_variables"
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
