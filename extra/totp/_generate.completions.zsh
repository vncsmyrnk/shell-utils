#!/usr/bin/env zsh

arguments="$1"
if grep -q ' ' <<<"$arguments"; then
  return
fi

entities=()
for file in $HOME/.secrets/totp/*(.); do
  file_basename_noext=$(basename $file | rev | cut -f2- -d "." | rev)
  entities+=("$file_basename_noext")
done

_describe 'options' entities
