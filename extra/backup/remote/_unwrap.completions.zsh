#!/usr/bin/env zsh

_files

arguments="$1"
if grep -q ' ' <<<"$arguments"; then
  return
fi

local -a my_opts
my_opts=(
  '--latest:use the latest backup'
)

_describe 'flags and commands' my_opts
