#!/usr/bin/env zsh

subcommand_level=2
shift "$subcommand_level" words
((CURRENT -= "$subcommand_level"))

_arguments \
  '1:file:_files' \
  "${common_flags[@]}"
