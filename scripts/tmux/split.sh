#!/usr/bin/env bash
set -e

# [help]
# Splits the current window both horizontally and vertically

tmux split-window -h &&
  tmux split-window -v
