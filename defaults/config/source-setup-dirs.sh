# vim: set ft=sh:

# [help]
# Script for sourcing predefined shell files. Useful for shell runtime configuration setups.
#
# shell-utils can source run commands configuration files automatically at $SU_RC_SOURCE_PATH.
# So if you have a specific setup for tools like p10k you can put all the config you want
# sourced on a folder at $SU_RC_SOURCE_PATH.
#
# To use this functionality, make sure to run the config task and source this file in your
# rc file:
#
# ```sh
# \. <(util config source-setup-dirs --to-stdout)
# ```

\. "$HOME/.config/util/vars"

source_setup_dir() {
  [ -d "$1" ] || return
  [ -f "$1/setup" ] && \. "$1/setup" # sources setup files first

  find "$1" -follow -type f -not -iname "setup" | while read -r rc_file; do
    \. "$rc_file"
  done
}

main() {
  [ -d "$SU_RC_SOURCE_PATH" ] || return

  find "$SU_RC_SOURCE_PATH"/* -type d | while read -r to_source_dir; do
    source_setup_dir "$to_source_dir"
  done
}

main "$@"
