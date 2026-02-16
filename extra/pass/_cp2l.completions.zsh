#!/usr/bin/env zsh

_arguments \
  '(-t --first-copy-timeout)'{-t,--first-copy-timeout}':timeout (seconds):_guard "[0-9]#" "integer"' \
  "${common_flags[@]}"

arguments="$1"
if grep -q ' ' <<<"$arguments"; then
  return
fi

entities=()
for file in $(fd . --base-directory ~/.password-store --relative-path -t f); do
  file_basename_noext=$(echo "$file" | rev | cut -f2- -d "." | rev)
  entities+=("$file_basename_noext")
done

_describe 'options' entities
