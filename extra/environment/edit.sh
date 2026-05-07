#!/usr/bin/env bash

# [help]
# Edits the sops secrets variables using $EDITOR

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
\. "$DIR/_variables"

sops "$_secrets_path"
