#!/usr/bin/env bash
set -e

_totp_secrets_dir=${SHELL_UTILS_TOTP_SECRETS_DIR:-"$HOME/.secrets/totp.tp"}
_totp_current_time=${SHELL_UTILS_TOTP_CURRENT_TIME:-"5 seconds"}
