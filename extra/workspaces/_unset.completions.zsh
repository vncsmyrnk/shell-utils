#!/usr/bin/env zsh

subcommand_level=2
shift "$subcommand_level" words
((CURRENT -= "$subcommand_level"))

_arguments \
  "${common_flags[@]}"

workspaces_result=$(util workspaces list --noheadings)
if [[ "$?" -ne 0 ]]; then
  return
fi

workspaces_result=$(awk '{ print $1 }' <<<"$workspaces_result")
workspaces_relative_dirs=$(
  xargs -I{} realpath {} --relative-to=. <<<"$workspaces_result"
)

workspaces=(${(f)"$(echo $workspaces_relative_dirs)"})
_describe 'workspaces' workspaces
