#!/usr/bin/env zsh

arguments="$1"
if grep -qE '.+ [^ ]+' <<<"$arguments"; then
  return
fi

_arguments \
  "${common_flags[@]}"

_files
