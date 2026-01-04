#!/usr/bin/env zsh

_files

arguments="$1"
if grep -q ' ' <<<"$arguments"; then
  return
fi

local -a my_opts
my_opts=(
  '-l:forces language instead of infering it from the mo path'
)

_describe 'flags and commands' my_opts
