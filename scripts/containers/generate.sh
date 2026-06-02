#!/usr/bin/env bash
set -e

# [help]
# Generates an encrypted container file formated using ext4
#
# Usage: util container generate [FILE] [SIZE]
#
# Example: util container generate containter.img 2G

: "${SHELL_UTILS_SCRIPTS_PATH:=}"
# shellcheck source=scripts/_lib.sh
\. "${SHELL_UTILS_SCRIPTS_PATH}/_lib.sh"

src="$1"
size="$2"
if [[ -z "$src" ]] || [[ -z "$size" ]]; then
  _lib_fatal "source and size are expected to generate the container."
fi

username=$(whoami)

# example: fallocate -l 2G ~/vault.img
fallocate -l "$size" "$src"
cryptsetup luksFormat "$src"

tmp_name="container-$(date +'%Y%m%d%H%M%S')"
sudo cryptsetup luksOpen "$src" "$tmp_name"
sudo mkfs.ext4 "/dev/mapper/$tmp_name"

sudo mount "/dev/mapper/$tmp_name" /mnt
sudo chown -R "$username:$username" /mnt
sudo umount /mnt

sudo cryptsetup luksClose "$tmp_name"
