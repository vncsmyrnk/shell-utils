#!/usr/bin/env bash
set -e

# [help]
# Invokes Nix garbage collection

nix-collect-garbage -d
