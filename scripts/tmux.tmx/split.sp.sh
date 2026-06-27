#!/usr/bin/env bash
set -eou pipefail

# [help]
# Splits the current window both horizontally and vertically
#
# Usage: util tmux split [FLAGS]
#
# Options:
#  --select-last-pane   Selects the last pane after split

select_last_pane=false
while [[ $# -gt 0 ]]; do
  case $1 in
  --select-last-pane)
    select_last_pane=true
    shift
    ;;
  --)
    shift
    break
    ;;
  *)
    break
    ;;
  esac
done

if ! current_pane_id=$(tmux list-panes -F '#{pane_id}' -f '#{m:1,#{pane_active}}'); then
  echo "failed to fetch current pane id, selecting current pane will not work." >&2
fi

tmux split-window -h
tmux split-window -v

if [[ "$select_last_pane" = false ]]; then
  tmux select-pane -t "$current_pane_id"
fi
