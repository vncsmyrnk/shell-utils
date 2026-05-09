#!/usr/bin/env zsh

subcommand_level=2
shift "$subcommand_level" words
((CURRENT -= "$subcommand_level"))

_arguments \
  '1:source:_files' \
  '2:mountpoint:_files' \
  "${common_flags[@]}"
