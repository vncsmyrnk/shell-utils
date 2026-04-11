#!/usr/bin/env zsh

\. "${0:a:h}/_variables"

_arguments \
  '--all' \
  "${common_flags[@]}"

arguments="$1"
if grep -q ' ' <<<"$arguments"; then
  return
fi

windows=()
for w in $(tmux list-windows -t "$SESSION_NAME" -F "#{window_name}" 2>/dev/null); do
  windows+=("$w")
done

_describe 'windows' windows
