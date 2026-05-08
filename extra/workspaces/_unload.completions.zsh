#!/usr/bin/env zsh

subcommand_level=2
shift "$subcommand_level" words
((CURRENT -= "$subcommand_level"))

_arguments \
  '(-f --file)'{-f,--file}'[vault file]:path:_files -/' \
  '*:file:_files'
