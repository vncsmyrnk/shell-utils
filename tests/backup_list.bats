#!/usr/bin/env bats

setup() {
  # shellcheck disable=SC2154
  TEST_ROOT="$BATS_TEST_TMPDIR/backup-list"
  BASH_PATH="$(command -v bash)"
  mkdir -p "$TEST_ROOT/bin"

  printf '#!%s\n' "$BASH_PATH" >"$TEST_ROOT/bin/rclone"
  cat >>"$TEST_ROOT/bin/rclone" <<'EOF'
printf '%s\n' "$*" >"$RCLONE_ARGS"
printf '%s\n' "${RCLONE_OUTPUT:-}"
EOF
  chmod +x "$TEST_ROOT/bin/rclone"

  # shellcheck disable=SC2154
  LIST_ENV=(
    "SHELL_UTILS_SCRIPTS_PATH=$BATS_TEST_DIRNAME/../scripts"
    "SHELL_UTILS_BACKUP_RCLONE_REMOTE=remote"
    "SHELL_UTILS_BACKUP_RCLONE_FOLDER=backups"
    "RCLONE_ARGS=$TEST_ROOT/rclone.args"
    "RCLONE_OUTPUT=$rclone_output"
    "PATH=$TEST_ROOT/bin:$PATH"
  )
}

run_list() {
  local rclone_output="${1:-}"

  # shellcheck disable=SC2154
  run env \
    "${LIST_ENV[@]}" \
    RCLONE_OUTPUT="$rclone_output" \
    "$BASH_PATH" "$BATS_TEST_DIRNAME/../scripts/backup.bkp/remote.rmt/list.ls.sh"
}

@test "fails when rclone is unavailable" {
  mkdir "$TEST_ROOT/empty-bin"
  # shellcheck disable=SC2030
  LIST_ENV+=(
    "PATH=$TEST_ROOT/empty-bin"
  )
  run_list

  [[ "$status" -eq 1 ]]
}

@test "lists backup filenames from the configured remote folder" {
  # shellcheck disable=SC2031
  LIST_ENV+=(
    "RCLONE_OUTPUT=$rclone_output"
  )
  run_list

  [[ "$status" -eq 0 ]]
  [[ "$(cat "$TEST_ROOT/rclone.args" || true)" == "ls remote:backups" ]]
}

@test "reports an empty remote without producing filenames" {
  run_list ""

  [[ "$status" -eq 0 ]]
  [[ "$output" == *"no files found."* ]]
}
