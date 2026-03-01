#!/usr/bin/env zsh

_arguments \
  '(-s --original-source)'{-s,--original-source}'[Only remove files existing on the original source]' \
  "${common_flags[@]}"

arguments="$1"
if grep -q ' ' <<<"$arguments"; then
  return
fi

local files=($(
  find "$SU_PATH" \
    -follow \
    -executable \
    -not -name "_*" \
    -printf "%P\n" |
    xargs -I{} sh -c 'echo {} | rev | cut -f2- -d "." | rev'
))

_describe 'options' files
