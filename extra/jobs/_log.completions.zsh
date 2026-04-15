#!/usr/bin/env zsh

\. "${0:a:h}/_variables"

_arguments \
  "-f" \
  "${common_flags[@]}"

arguments="$1"
if grep -q ' ' <<<"$arguments"; then
  return
fi

windows=()
for w in $(tmux list-windows -t "$_jobs_session_name" -F "#{window_name}" 2>/dev/null); do
  windows+=("$w")
done

_describe 'windows' windows
