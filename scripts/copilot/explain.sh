#!/usr/bin/env bash
set -e

# [help]
# Uses GH Copilot CLI to explain something.
#
# Example: `util copilot explain how does the ln command work`

gh copilot explain "$@"
