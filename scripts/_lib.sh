#!/usr/bin/env bash

BOLD='\033[1m'
BLUE='\033[1;34m'
NC='\033[0m'

ARROW="==>"

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

_lib_log_step_header() {
  local no_upper_spacing=false
  while [[ $# -gt 0 ]]; do
    case $1 in
    --no-upper-spacing)
      no_upper_spacing=true
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
    esac
  done
  if [[ "$no_upper_spacing" = false ]]; then
    echo ""
  fi
  echo -e "${BOLD}${BLUE}${ARROW} $1 ${NC}"
}
