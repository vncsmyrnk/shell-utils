#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
  echo "This script required sudo privileges"
  exit 1
fi

path_iso="$1"
device="$2"

dd if="$path_iso" of="$device" bs=4M status=progress
