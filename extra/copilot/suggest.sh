#!/bin/sh

# [help]
# Uses GH Copilot CLI to suggest commands.
#
# Example: `util copilot suggest how do I list and sort files by creation date`

gh copilot suggest "$@"
