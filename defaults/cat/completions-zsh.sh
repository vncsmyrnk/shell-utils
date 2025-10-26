#!/bin/sh

# [help]
# Sets the completions file for zsh.
#
# This enables completions for custom commands and options.
#
# Usage: `. <(util cat completions-zsh)`

cat <<EOF
[ -d "\$SU_COMPLETIONS_PATH" ] && fpath=("\$SU_COMPLETIONS_PATH" \$fpath)
EOF
