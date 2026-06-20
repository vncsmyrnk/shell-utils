#!/usr/bin/env bash
set -e

# [help]
# Updates system packages

: "${SHELL_UTILS_SCRIPTS_PATH:=}"
# shellcheck source=scripts/_lib.sh
\. "${SHELL_UTILS_SCRIPTS_PATH}/_lib.sh"

main() {
  _lib_log_step_header --no-upper-spacing "Updating system packages"

  # shellcheck disable=SC2310
  if exists apt; then sudo apt-get update && sudo apt-get upgrade; fi
  # shellcheck disable=SC2310
  if exists brew; then brew update && brew upgrade; fi
  # shellcheck disable=SC2310
  if exists yay; then yay; fi

  _lib_log_step_header "Updating shell environments"

  # shellcheck disable=SC2310
  if exists zsh; then
    zsh -f -c '
      ZINIT_HOME="$HOME/.local/share/zinit/zinit.git"
      if [[ -f "${ZINIT_HOME}/zinit.zsh" ]] && [[ $(stat -c "%a" "${ZINIT_HOME}/zinit.zsh") == "644" ]]; then
        source "${ZINIT_HOME}/zinit.zsh"
        zinit self-update
        zinit update --parallel
      fi' 2>&1
  fi
}

exists() {
  command -v "$1" >/dev/null
}

main "$@"
