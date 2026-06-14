#!/usr/bin/env bash
set -e

# [help]
# Generates an encrypted container file formated using ext4
#
# Usage: util container generate <name> <size>
#
# Example: util container generate projects 2G

: "${SHELL_UTILS_SCRIPTS_PATH:=}"
# shellcheck source=scripts/_lib.sh
\. "${SHELL_UTILS_SCRIPTS_PATH}/_lib.sh"

: "${SHELL_UTILS_SCRIPT_DIRNAME:=}"
# shellcheck source=scripts/containers.cnt/_variables.sh
\. "${SHELL_UTILS_SCRIPT_DIRNAME}/_variables.sh"
: "${_containers_image_dir:=}"

filesystem="ext4"
while [[ $# -gt 0 ]]; do
  case $1 in
  --filesystem)
    filesystem="$2"
    shift 2
    ;;
  --filesystem=*)
    filesystem="${1#*=}"
    shift
    ;;
  --)
    shift
    break
    ;;
  *)
    break
    ;;
  esac
done

if [[ "$filesystem" != "ext4" ]]; then
  echo "unsupported filesystem." >&2
  exit 1
fi

name="$1"
size="$2"
if [[ -z "$name" ]] || [[ -z "$size" ]]; then
  _lib_fatal "source and size are expected to generate the container."
fi

username=$(whoami)
src="${_containers_image_dir}/$name.img"

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
