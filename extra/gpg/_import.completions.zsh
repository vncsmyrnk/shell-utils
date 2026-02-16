#!/usr/bin/env zsh

_arguments \
  "--private-key=[Path to private key]:file:_files" \
  "--public-key=[Path to public key]:file:_files" \
  "--ownertrust=[Path to public key]:file:_files" \
  "${common_flags[@]}"
