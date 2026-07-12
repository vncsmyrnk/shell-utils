#!/usr/bin/env bash

_install_mock() {
  local command="$1"
  local bin_dir="$2"
  local target

  if [[ -z "$command" ]] || [[ -z "$bin_dir" ]]; then
    printf '%s\n' \
      '_install_mock: command and bin directory are required' >&2
    return 1
  fi
  if [[ ! -d "$bin_dir" ]]; then
    printf '_install_mock: bin directory not found: %s\n' \
      "$bin_dir" >&2
    return 1
  fi

  target="$bin_dir/$command"
  if ! cat >"$target"; then
    printf '_install_mock: failed to write mock: %s\n' "$target" >&2
    return 1
  fi
  if ! chmod +x "$target"; then
    printf '_install_mock: failed to make mock executable: %s\n' \
      "$target" >&2
    return 1
  fi
}

mock_chown() {
  local bin_dir="$1"

  {
    cat <<EOF || true
#!$(command -v bash)

EOF

    cat <<'EOF' || true
command_name='chown'
args_file="${MOCK_ARGS_DIR:?mock_chown: MOCK_ARGS_DIR is required}"
args_file="$args_file/$command_name.args"
output_file="${MOCK_OUTPUT_DIR:-}/$command_name"
status_file="${MOCK_STATUS_DIR:-}/$command_name"
printf '%s\0' "$@" >>"$args_file"

if [[ -f "$status_file" ]]; then
  read -r status <"$status_file"
  exit "${status:-0}"
fi
if [[ -s "$output_file" ]]; then
  output=$(<"$output_file")
  printf '%s\n' "$output"
fi
EOF
  } | _install_mock 'chown' "$bin_dir"
}

mock_column() {
  local bin_dir="$1"

  {
    cat <<EOF || true
#!$(command -v bash)

EOF

    cat <<'EOF' || true
#!/usr/bin/env bash

command_name='column'
args_file="${MOCK_ARGS_DIR:?mock_column: MOCK_ARGS_DIR is required}"
args_file="$args_file/$command_name.args"
output_file="${MOCK_OUTPUT_DIR:-}/$command_name"
status_file="${MOCK_STATUS_DIR:-}/$command_name"
printf '%s\0' "$@" >>"$args_file"

if [[ -f "$status_file" ]]; then
  read -r status <"$status_file"
  exit "${status:-0}"
fi
if [[ -s "$output_file" ]]; then
  output=$(<"$output_file")
  printf '%s\n' "$output"
fi
if [[ "$1" == '-N' ]]; then
  printf '%s\n' "${2//,/ }"
elif [[ "$2" == '-N' ]]; then
  printf '%s\n' "${3//,/ }"
fi
cat
EOF
  } | _install_mock 'column' "$bin_dir"
}

mock_cryptsetup() {
  local bin_dir="$1"

  {
    cat <<EOF || true
#!$(command -v bash)

EOF

    cat <<'EOF' || true
#!/usr/bin/env bash

command_name='cryptsetup'
args_file="${MOCK_ARGS_DIR:?mock_cryptsetup: MOCK_ARGS_DIR is required}"
args_file="$args_file/$command_name.args"
output_file="${MOCK_OUTPUT_DIR:-}/$command_name"
status_file="${MOCK_STATUS_DIR:-}/$command_name"
printf '%s\0' "$@" >>"$args_file"

if [[ -f "$status_file" ]]; then
  read -r status <"$status_file"
  exit "${status:-0}"
fi
if [[ -s "$output_file" ]]; then
  output=$(<"$output_file")
  printf '%s\n' "$output"
fi
EOF
  } | _install_mock 'cryptsetup' "$bin_dir"
}

mock_date() {
  local bin_dir="$1"

  {
    cat <<EOF || true
#!$(command -v bash)

EOF

    cat <<'EOF' || true
#!/usr/bin/env bash

command_name='date'
args_file="${MOCK_ARGS_DIR:?mock_date: MOCK_ARGS_DIR is required}"
args_file="$args_file/$command_name.args"
output_file="${MOCK_OUTPUT_DIR:-}/$command_name"
status_file="${MOCK_STATUS_DIR:-}/$command_name"
printf '%s\0' "$@" >>"$args_file"

if [[ -f "$status_file" ]]; then
  read -r status <"$status_file"
  exit "${status:-0}"
fi
if [[ -s "$output_file" ]]; then
  output=$(<"$output_file")
  printf '%s\n' "$output"
fi
[[ -f "$output_file" ]] || printf '20260101000000\n'
EOF
  } | _install_mock 'date' "$bin_dir"
}

mock_envsubst() {
  local bin_dir="$1"

  {
    cat <<EOF || true
#!$(command -v bash)

EOF

    cat <<'EOF' || true
#!/usr/bin/env bash

command_name='envsubst'
args_file="${MOCK_ARGS_DIR:?mock_envsubst: MOCK_ARGS_DIR is required}"
args_file="$args_file/$command_name.args"
output_file="${MOCK_OUTPUT_DIR:-}/$command_name"
status_file="${MOCK_STATUS_DIR:-}/$command_name"
printf '%s\0' "$@" >>"$args_file"

if [[ -f "$status_file" ]]; then
  read -r status <"$status_file"
  exit "${status:-0}"
fi
if [[ -s "$output_file" ]]; then
  output=$(<"$output_file")
  printf '%s\n' "$output"
else
  read -r value
  printf '%s\n' "${value//\$HOME/$HOME}"
fi
EOF
  } | _install_mock 'envsubst' "$bin_dir"
}

mock_fallocate() {
  local bin_dir="$1"

  {
    cat <<EOF || true
#!$(command -v bash)

EOF

    cat <<'EOF' || true
#!/usr/bin/env bash

command_name='fallocate'
args_file="${MOCK_ARGS_DIR:?mock_fallocate: MOCK_ARGS_DIR is required}"
args_file="$args_file/$command_name.args"
output_file="${MOCK_OUTPUT_DIR:-}/$command_name"
status_file="${MOCK_STATUS_DIR:-}/$command_name"
printf '%s\0' "$@" >>"$args_file"

if [[ -f "$status_file" ]]; then
  read -r status <"$status_file"
  exit "${status:-0}"
fi
if [[ -s "$output_file" ]]; then
  output=$(<"$output_file")
  printf '%s\n' "$output"
fi
: >"${@: -1}"
EOF
  } | _install_mock 'fallocate' "$bin_dir"
}

mock_find() {
  local bin_dir="$1"

  {
    cat <<EOF || true
#!$(command -v bash)

EOF

    cat <<'EOF' || true
#!/usr/bin/env bash

command_name='find'
args_file="${MOCK_ARGS_DIR:?mock_find: MOCK_ARGS_DIR is required}"
args_file="$args_file/$command_name.args"
output_file="${MOCK_OUTPUT_DIR:-}/$command_name"
status_file="${MOCK_STATUS_DIR:-}/$command_name"
printf '%s\0' "$@" >>"$args_file"

if [[ -f "$status_file" ]]; then
  read -r status <"$status_file"
  exit "${status:-0}"
fi
if [[ -s "$output_file" ]]; then
  output=$(<"$output_file")
  printf '%s\n' "$output"
fi
EOF
  } | _install_mock 'find' "$bin_dir"
}

mock_fuser() {
  local bin_dir="$1"

  {
    cat <<EOF || true
#!$(command -v bash)

EOF

    cat <<'EOF' || true
#!/usr/bin/env bash

command_name='fuser'
args_file="${MOCK_ARGS_DIR:?mock_fuser: MOCK_ARGS_DIR is required}"
args_file="$args_file/$command_name.args"
output_file="${MOCK_OUTPUT_DIR:-}/$command_name"
status_file="${MOCK_STATUS_DIR:-}/$command_name"
printf '%s\0' "$@" >>"$args_file"

if [[ "$*" == *' -k'* ]]; then
  printf '1\n' >"$status_file"
  exit 0
fi
if [[ -f "$status_file" ]]; then
  read -r status <"$status_file"
  exit "${status:-0}"
fi
if [[ -s "$output_file" ]]; then
  output=$(<"$output_file")
  printf '%s\n' "$output"
fi
EOF
  } | _install_mock 'fuser' "$bin_dir"
}

mock_jq() {
  local bin_dir="$1"

  {
    cat <<EOF || true
#!$(command -v bash)

EOF

    cat <<'EOF' || true
#!/usr/bin/env bash

command_name='jq'
args_file="${MOCK_ARGS_DIR:?mock_jq: MOCK_ARGS_DIR is required}"
args_file="$args_file/$command_name.args"
output_file="${MOCK_OUTPUT_DIR:-}/$command_name"
status_file="${MOCK_STATUS_DIR:-}/$command_name"
printf '%s\0' "$@" >>"$args_file"

if [[ -f "$status_file" ]]; then
  read -r status <"$status_file"
  exit "${status:-0}"
fi
if [[ -s "$output_file" ]]; then
  output=$(<"$output_file")
  printf '%s\n' "$output"
fi
EOF
  } | _install_mock 'jq' "$bin_dir"
}

mock_losetup() {
  local bin_dir="$1"

  {
    cat <<EOF || true
#!$(command -v bash)

EOF

    cat <<'EOF' || true
#!/usr/bin/env bash

command_name='losetup'
args_file="${MOCK_ARGS_DIR:?mock_losetup: MOCK_ARGS_DIR is required}"
args_file="$args_file/$command_name.args"
output_file="${MOCK_OUTPUT_DIR:-}/$command_name"
status_file="${MOCK_STATUS_DIR:-}/$command_name"
printf '%s\0' "$@" >>"$args_file"

if [[ -f "$status_file" ]]; then
  read -r status <"$status_file"
  exit "${status:-0}"
fi
if [[ -s "$output_file" ]]; then
  output=$(<"$output_file")
  printf '%s\n' "$output"
fi
EOF
  } | _install_mock 'losetup' "$bin_dir"
}

mock_lsblk() {
  local bin_dir="$1"

  {
    cat <<EOF || true
#!$(command -v bash)

EOF

    cat <<'EOF' || true
#!/usr/bin/env bash

command_name='lsblk'
args_file="${MOCK_ARGS_DIR:?mock_lsblk: MOCK_ARGS_DIR is required}"
args_file="$args_file/$command_name.args"
output_file="${MOCK_OUTPUT_DIR:-}/$command_name"
status_file="${MOCK_STATUS_DIR:-}/$command_name"
printf '%s\0' "$@" >>"$args_file"

if [[ -f "$status_file" ]]; then
  read -r status <"$status_file"
  exit "${status:-0}"
fi
if [[ -s "$output_file" ]]; then
  output=$(<"$output_file")
  printf '%s\n' "$output"
fi
EOF
  } | _install_mock 'lsblk' "$bin_dir"
}

mock_mkdir() {
  local bin_dir="$1"

  {
    cat <<EOF || true
#!$(command -v bash)

EOF

    cat <<'EOF' || true
#!/usr/bin/env bash

command_name='mkdir'
args_file="${MOCK_ARGS_DIR:?mock_mkdir: MOCK_ARGS_DIR is required}"
args_file="$args_file/$command_name.args"
output_file="${MOCK_OUTPUT_DIR:-}/$command_name"
status_file="${MOCK_STATUS_DIR:-}/$command_name"
printf '%s\0' "$@" >>"$args_file"

if [[ -f "$status_file" ]]; then
  read -r status <"$status_file"
  exit "${status:-0}"
fi
if [[ -s "$output_file" ]]; then
  output=$(<"$output_file")
  printf '%s\n' "$output"
fi
EOF
  } | _install_mock 'mkdir' "$bin_dir"
}

mock_mkfs_ext4() {
  local bin_dir="$1"

  {
    cat <<EOF || true
#!$(command -v bash)

EOF

    cat <<'EOF' || true
#!/usr/bin/env bash

command_name='mkfs.ext4'
args_file="${MOCK_ARGS_DIR:?mock_mkfs_ext4: MOCK_ARGS_DIR is required}"
args_file="$args_file/$command_name.args"
output_file="${MOCK_OUTPUT_DIR:-}/$command_name"
status_file="${MOCK_STATUS_DIR:-}/$command_name"
printf '%s\0' "$@" >>"$args_file"

if [[ -f "$status_file" ]]; then
  read -r status <"$status_file"
  exit "${status:-0}"
fi
if [[ -s "$output_file" ]]; then
  output=$(<"$output_file")
  printf '%s\n' "$output"
fi
EOF
  } | _install_mock 'mkfs.ext4' "$bin_dir"
}

mock_mount() {
  local bin_dir="$1"

  {
    cat <<EOF || true
#!$(command -v bash)

EOF

    cat <<'EOF' || true
#!/usr/bin/env bash

command_name='mount'
args_file="${MOCK_ARGS_DIR:?mock_mount: MOCK_ARGS_DIR is required}"
args_file="$args_file/$command_name.args"
output_file="${MOCK_OUTPUT_DIR:-}/$command_name"
status_file="${MOCK_STATUS_DIR:-}/$command_name"
printf '%s\0' "$@" >>"$args_file"

if [[ -f "$status_file" ]]; then
  read -r status <"$status_file"
  exit "${status:-0}"
fi
if [[ -s "$output_file" ]]; then
  output=$(<"$output_file")
  printf '%s\n' "$output"
fi
EOF
  } | _install_mock 'mount' "$bin_dir"
}

mock_ssh_add() {
  local bin_dir="$1"

  {
    cat <<EOF || true
#!$(command -v bash)

EOF

    cat <<'EOF' || true
#!/usr/bin/env bash

command_name='ssh-add'
args_file="${MOCK_ARGS_DIR:?mock_ssh_add: MOCK_ARGS_DIR is required}"
args_file="$args_file/$command_name.args"
output_file="${MOCK_OUTPUT_DIR:-}/$command_name"
status_file="${MOCK_STATUS_DIR:-}/$command_name"
printf '%s\0' "$@" >>"$args_file"

if [[ -f "$status_file" ]]; then
  read -r status <"$status_file"
  exit "${status:-0}"
fi
if [[ -s "$output_file" ]]; then
  output=$(<"$output_file")
  printf '%s\n' "$output"
fi
EOF
  } | _install_mock 'ssh-add' "$bin_dir"
}

mock_stow() {
  local bin_dir="$1"

  {
    cat <<EOF || true
#!$(command -v bash)

EOF

    cat <<'EOF' || true
#!/usr/bin/env bash

command_name='stow'
args_file="${MOCK_ARGS_DIR:?mock_stow: MOCK_ARGS_DIR is required}"
args_file="$args_file/$command_name.args"
output_file="${MOCK_OUTPUT_DIR:-}/$command_name"
status_file="${MOCK_STATUS_DIR:-}/$command_name"
printf '%s\0' "$@" >>"$args_file"

if [[ -f "$status_file" ]]; then
  read -r status <"$status_file"
  exit "${status:-0}"
fi
if [[ -s "$output_file" ]]; then
  output=$(<"$output_file")
  printf '%s\n' "$output"
fi
EOF
  } | _install_mock 'stow' "$bin_dir"
}

mock_sudo() {
  local bin_dir="$1"

  {
    cat <<EOF || true
#!$(command -v bash)

EOF

    cat <<'EOF' || true
#!/usr/bin/env bash

command_name='sudo'
args_file="${MOCK_ARGS_DIR:?mock_sudo: MOCK_ARGS_DIR is required}"
args_file="$args_file/$command_name.args"
status_file="${MOCK_STATUS_DIR:-}/$command_name"
printf '%s\0' "$@" >>"$args_file"

if [[ -f "$status_file" ]]; then
  read -r status <"$status_file"
  exit "${status:-0}"
fi
if [[ "$1" == '-v' ]]; then
  exit 0
fi
exec "$@"
EOF
  } | _install_mock 'sudo' "$bin_dir"
}

mock_umount() {
  local bin_dir="$1"

  {
    cat <<EOF || true
#!$(command -v bash)

EOF

    cat <<'EOF' || true
#!/usr/bin/env bash

command_name='umount'
args_file="${MOCK_ARGS_DIR:?mock_umount: MOCK_ARGS_DIR is required}"
args_file="$args_file/$command_name.args"
output_file="${MOCK_OUTPUT_DIR:-}/$command_name"
status_file="${MOCK_STATUS_DIR:-}/$command_name"
printf '%s\0' "$@" >>"$args_file"

if [[ -f "$status_file" ]]; then
  read -r status <"$status_file"
  exit "${status:-0}"
fi
if [[ -s "$output_file" ]]; then
  output=$(<"$output_file")
  printf '%s\n' "$output"
fi
EOF
  } | _install_mock 'umount' "$bin_dir"
}

mock_whoami() {
  local bin_dir="$1"

  {
    cat <<EOF || true
#!$(command -v bash)

EOF

    cat <<'EOF' || true
#!/usr/bin/env bash

command_name='whoami'
args_file="${MOCK_ARGS_DIR:?mock_whoami: MOCK_ARGS_DIR is required}"
args_file="$args_file/$command_name.args"
output_file="${MOCK_OUTPUT_DIR:-}/$command_name"
status_file="${MOCK_STATUS_DIR:-}/$command_name"
printf '%s\0' "$@" >>"$args_file"

if [[ -f "$status_file" ]]; then
  read -r status <"$status_file"
  exit "${status:-0}"
fi
if [[ -s "$output_file" ]]; then
  output=$(<"$output_file")
  printf '%s\n' "$output"
fi
EOF
  } | _install_mock 'whoami' "$bin_dir"
}

mock_sops() {
  local bin_dir="$1"

  {
    cat <<EOF || true
#!$(command -v bash)

EOF

    cat <<'EOF' || true
#!/usr/bin/env bash

command_name='sops'
args_file="${MOCK_ARGS_DIR:?mock_sops: MOCK_ARGS_DIR is required}"
args_file="$args_file/$command_name.args"
output_file="${MOCK_OUTPUT_DIR:-}/$command_name"
status_file="${MOCK_STATUS_DIR:-}/$command_name"
printf '%s\0' "$@" >>"$args_file"

if [[ -f "$status_file" ]]; then
  read -r status <"$status_file"
  exit "${status:-0}"
fi
if [[ -s "$output_file" ]]; then
  output=$(<"$output_file")
  printf '%s\n' "$output"
fi
EOF
  } | _install_mock 'sops' "$bin_dir"
}
