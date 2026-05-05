#!/usr/bin/env bash

# [help]
# Generates an encrypted container file formated using ext4

size="$1"
src="$2"
name="$3"

if [[ -z "$size" ]] && [[ -z "$src" ]] || [[ -z "$name" ]]; then
  exit 1
fi

# example: fallocate -l 2G ~/vault.img
fallocate -l "$size" "$src"
cryptsetup luksFormat "$src"
sudo cryptsetup luksOpen "$src" "$name"
sudo mkfs.ext4 "/dev/mapper/$name"

sudo mount "/dev/mapper/$name" /mnt
sudo chown -R "$(whoami):$(whoami)" /mnt
sudo umount /mnt

sudo cryptsetup luksClose "$name"
