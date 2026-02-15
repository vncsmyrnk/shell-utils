#!/usr/bin/env bash

# [help]
# Imports a gpg key ID using the private and public keys and the trust backup

while [[ $# -gt 0 ]]; do
  case $1 in
  --private-key)
    private_key_path="$2"
    shift 2
    ;;
  --private-key=*)
    private_key_path="${1#*=}"
    shift
    ;;
  --public-key)
    public_key_path="$2"
    shift 2
    ;;
  --public-key=*)
    public_key_path="${1#*=}"
    shift
    ;;
  --ownertrust)
    ownertrust_path="$2"
    shift 2
    ;;
  --ownertrust=*)
    ownertrust_path="${1#*=}"
    shift
    ;;
  *)
    break
    ;;
  esac
done

error() {
  printf "%s\n" "$1"
  exit 1
}

if [[ -z "$private_key_path" ]] || [[ -z "$public_key_path" ]] || [[ -z "$ownertrust_path" ]]; then
  error "usage: util gpg import --private-key=<private_key_path> --public-key=<public_key_path> --ownertrust=<ownertrust_path>"
fi

import_gpg_key() {
  gpg --import "$private_key_path"
  gpg --import "$public_key_path"
  gpg --import-ownertrust "$ownertrust_path"
}

main() {
  import_gpg_key
}

main
