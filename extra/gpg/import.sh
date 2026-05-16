#!/usr/bin/env bash

# [help]
# Imports a gpg key ID using the private and public keys and the trust backup
#
# Usage: util gpg import [OPTIONS]
#
# Options:
#  --private-key   GPG key's private key, exportable via `gpg --export-secret-keys`
#  --public-key    GPG key's public key, exportable via `gpg --export `
#  --ownertrust    GPG key's ownertrust data base, exportable via `gpg --export-ownertrust`

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

if [[ -z "$private_key_path" ]] || [[ -z "$public_key_path" ]] || [[ -z "$ownertrust_path" ]]; then
  _lib_fatal "private, public keys and ownertrust DB are required."
fi

gpg --import "$private_key_path"
gpg --import "$public_key_path"
gpg --import-ownertrust "$ownertrust_path"
