#!/bin/zsh

# [help]
# Sets the completions file for zsh.
#
# This enables completions for custom commands and options.
#
# Usage: `. <(util cat completions zsh)`

[ -d "$SU_COMPLETIONS_PATH/zsh" ] && fpath=("$SU_COMPLETIONS_PATH/zsh" $fpath)
