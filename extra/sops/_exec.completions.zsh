#!/usr/bin/env zsh

_arguments \
  '(-f --file)'{-f,--file}'[sops file]:path:_files -/' \
  "${common_flags[@]}"
