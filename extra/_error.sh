#!/usr/bin/env bash

set -e

# Use a namespaced global variable to avoid collisions in the main script
__err_tmp_file=$(mktemp)

# Redirect stderr to the temp file, saving the terminal to fd 9
exec 9>&2
exec 2>"$__err_tmp_file"

__err_cleanup() {
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    cat "$__err_tmp_file" >&9
  fi

  # Restore stderr and cleanup
  exec 2>&9 9>&-
  rm -f "$__err_tmp_file"

  exit "$exit_code"
}

trap __err_cleanup EXIT
