#!/bin/sh

UTIL_SCRIPTS_PATH=$HOME/.config/utils

if ! command -v find >/dev/null; then
  echo "find is necessary for util to work. Please install it before using this executable."
  exit 1
fi

util_file=$(
find $UTIL_SCRIPTS_PATH \
  -iname "$1.*" \
  -type f \
  -follow \
  -executable
)

if [ -z "$util_file" ]; then
  echo "Util file not found. Check \033[1m$UTIL_SCRIPTS_PATH\033[0m for commands available."
  echo "\033[2mTip: pass file without the extension and make it sure it is executable.\033[0m"
  exit 1
fi

file_matches=$(echo "$util_file" | wc -l)
if [ $file_matches -gt 1 ]; then
  echo "Ambiguity detected. Make sure the scripts at $UTIL_SCRIPTS_PATH have no name conflict."
  exit 1
fi

shift
$util_file "$@"
