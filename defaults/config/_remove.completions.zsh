#!/usr/bin/env zsh

_arguments \
  '(-d --dry-run)'{-d,--dry-run}'[Show what would be done without making changes]' \
  "${common_flags[@]}"

arguments="$1"
if grep -q ' ' <<<"$arguments"; then
  return
fi

local files=($(
  find "$SU_SCRIPTS_PATH" \
    -follow \
    -executable \
    -not -name "on-update*" \
    -not -name "_*" \
    -printf "%P\n" |
    xargs -I{} sh -c 'echo {} | rev | cut -f2- -d "." | rev'
))

_describe 'options' files
