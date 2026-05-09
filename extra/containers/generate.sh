#!/usr/bin/env bash

# [help]
# Generates an encrypted container file formated using ext4
#
# Usage: util container generate <path/to/img> <size>
# Example: util container generate containter.img 2G

src="$1"
size="$2"

if [[ -z "$src" ]] || [[ -z "$size" ]]; then
  echo "source and size are expected to generate the container."
  exit 1
fi

# example: fallocate -l 2G ~/vault.img
fallocate -l "$size" "$src"
cryptsetup luksFormat "$src"

tmp_name="container-$(date +'%Y%m%d%H%M%S')"
sudo cryptsetup luksOpen "$src" "$tmp_name"
sudo mkfs.ext4 "/dev/mapper/$tmp_name"

sudo mount "/dev/mapper/$tmp_name" /mnt
sudo chown -R "$(whoami):$(whoami)" /mnt
sudo umount /mnt

sudo cryptsetup luksClose "$tmp_name"
