#!/usr/bin/env zsh

local persistent_flags=(
  '--help'
)

case "$1" in
add)
  _arguments \
    '(-t --target-name)'{-t,--target-name}'[Custom name for the target symlink]:name:' \
    '(-p --parent-path)'{-p,--parent-path}'[Parent path relative to scripts directory]:path:_files -/' \
    '(-f --force)'{-f,--force}'[Force overwrite without confirmation]' \
    "${persistent_flags[@]}" \
    '3:script file:_files'
  return
  ;;
remove)
  local -a entries=($(
    cd ~/.config/shell-utils/scripts || echo ""
    find -not -name "_*" -not -name "help" | cut -b 3- | rev | cut -f2- -d "." | rev
  ))
  echo "$entries" >>/tmp/test
  _arguments \
    '(-f --force)'{-f,--force}'[Force overwrite without confirmation]' \
    "${persistent_flags[@]}" \
    "3:path:(${entries})"
  return
  ;;
esac

subcommands=(
  'add'
  'remove'
  "${persistent_flags[@]}"
)
_describe 'config-subcommands' subcommands
