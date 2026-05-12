#!/usr/bin/env zsh

subcommand_level=2
shift "$subcommand_level" words
((CURRENT -= "$subcommand_level"))

_arguments \
  "${common_flags[@]}"

containers_result=$(util containers list --noheadings)
if [[ "$?" -ne 0 ]]; then
  return
fi

containers_result=$(awk '{ print $1 }' <<<"$containers_result")
containers_relative_dirs=$(
  xargs -I{} realpath {} --relative-to=. <<<"$containers_result"
)

containers=(${(f)"$(echo $containers_relative_dirs)"})
_describe 'containers' containers
