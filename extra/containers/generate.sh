#!/usr/bin/env bash

# [help]
# Generates an encrypted container file formated using ext4
#
# Usage: util container generate [FILE] [SIZE]
#
# Example: util container generate containter.img 2G

# shellcheck source=extra/_error.sh
if ! e=$(util-fetch "$(realpath "./../_error.sh" || true)"); then
  exit 1
fi
\. <(echo "$e")

# shellcheck source=extra/_lib.sh
if ! e=$(util-fetch "$(realpath "./../_lib.sh" || true)"); then
  exit 1
fi
\. <(echo "$e")

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
