#!/usr/bin/env bash

# [help]
# Exec a command setting sops secrets on the environent
#
# This allows the secrets to never be decrypted on physical drive.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
\. "$DIR/_variables"

sops exec-env "$_secrets_path" "$*"
