#!/bin/sh

# [help]
# Sources all files at \033[1m"SU_RC_SOURCE_PATH\033[0m.
#
# Useful for making rc configuration files more sucint. Copy or stow your configuration files to $SU_RC_SOURCE_PATH and they will be automatically loaded.
#
# It can also be directly sourced via `. "$HOME/.config/util/source_setup_dirs"`
#
# Usage: `. <(util cat source-setup-dirs)`

cat $HOME/.config/util/source_setup_dirs
