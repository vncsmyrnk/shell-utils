#!/usr/bin/env zsh

subcommand_level=2

if [[ -z "$2" ]] || [[ "$1" = "--file" ]]; then
  if [[ "$#" -lt 3 ]]; then # Skips flag suggestions when `--file` is filled
    _arguments \
      '(-f --file)'{-f,--file}'[sops file]:path:_files -/' \
      "${common_flags[@]}"
  fi
  subcommand_level=4 # Shifts all user prompt and avoids suggesting existing commands
fi

if [[ -z "$1" ]]; then
  subcommand_level=2 # Suggests existing commands when prompt is empty
fi

shift "$subcommand_level" words
((CURRENT -= "$subcommand_level"))

_precommand "$@" 2>/dev/null # Suppresses `shift count must be <= $#`
