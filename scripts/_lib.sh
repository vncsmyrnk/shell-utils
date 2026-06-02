#!/usr/bin/env bash

_lib_files_filename_noext() {
  if ! name=$(basename "$1"); then
    echo "basename: $name" >&2
    exit 1
  fi

  if ! reversed=$(rev <<<"$name"); then
    echo "rev: $reversed" >&2
    exit 1
  fi

  if ! reversed_noext=$(cut -f2 -d "." <<<"$reversed"); then
    echo "cut: $reversed" >&2
    exit 1
  fi

  if ! noext=$(rev <<<"$reversed_noext"); then
    echo "rev: $noext" >&2
    exit 1
  fi

  echo "$noext"
}

_lib_fatal() {
  echo -e "$1" >&1
  exit 1
}
