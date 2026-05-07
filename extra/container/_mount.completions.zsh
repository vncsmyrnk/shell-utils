#!/usr/bin/env zsh

subcommand_level=2
shift "$subcommand_level" words
((CURRENT -= "$subcommand_level"))

_arguments \
  '(-f --force)'{-f,--force}'[force recreation if destination exists]' \
  '1:file:_files'
