#!/usr/bin/env bash

# [help]
# Starts a new shell instance with all sops secrets

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
\. "$DIR/_variables"

sops exec-env "$_secrets_path" "$SHELL"
