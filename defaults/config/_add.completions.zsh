#!/usr/bin/env zsh

arguments="$1"
if ! grep -q ' ' <<<"$arguments"; then
  _files
  return
fi

_arguments \
  '(-t --target-name)'{-t,--target-name}'[Custom name for the target symlink]:name:' \
  '(-p --parent-path)'{-p,--parent-path}'[Parent path relative to scripts directory]:path:_files -/' \
  '(-f --force)'{-f,--force}'[Force overwrite without confirmation]' \
  '(-d --dry-run)'{-d,--dry-run}'[Show what would be done without making changes]' \
  "${common_flags[@]}"
