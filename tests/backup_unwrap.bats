#!/usr/bin/env bats

setup() {
  # shellcheck disable=SC2154
  TEST_ROOT="$BATS_TEST_TMPDIR/backup-unwrap"
  BASH_PATH="$(command -v bash)"
  mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/destination"

  printf '#!%s\n' "$(command -v bash || true)" >"$TEST_ROOT/bin/date"
  cat >>"$TEST_ROOT/bin/date" <<'EOF'
printf '20260101000000\n'
EOF

  printf '#!%s\n' "$BASH_PATH" >"$TEST_ROOT/bin/rclone"
  cat >>"$TEST_ROOT/bin/rclone" <<'EOF'
printf '%s\0' "$@" >>"$RCLONE_ARGS"
if [[ "$1" == "ls" ]]; then
  printf '%s\n' "${RCLONE_OUTPUT:-}"
elif [[ "$1" == "copy" ]]; then
  : >"$RCLONE_DEST/backup_20260101000000.zip.enc"
fi
EOF

  printf '#!%s\n' "$BASH_PATH" >"$TEST_ROOT/bin/openssl"
  cat >>"$TEST_ROOT/bin/openssl" <<'EOF'
printf '%s\0' "$@" >>"$OPENSSL_ARGS"
for ((index = 1; index <= $#; index++)); do
  if [[ "${!index}" == "-out" ]]; then
    output_index=$((index + 1))
    : >"${!output_index}"
    break
  fi
done
EOF

  printf '#!%s\n' "$BASH_PATH" >"$TEST_ROOT/bin/unzip"
  cat >>"$TEST_ROOT/bin/unzip" <<'EOF'
printf '%s\0' "$@" >>"$UNZIP_ARGS"
EOF

  printf '#!%s\n' "$(command -v bash || true)" >"$TEST_ROOT/bin/failing-rclone"
  cat >>"$TEST_ROOT/bin/failing-rclone" <<'EOF'
printf 'rclone failed\n' >&2
exit 9
EOF

  chmod +x "$TEST_ROOT/bin/"*

  # shellcheck disable=SC2154
  UNWRAP_ENV=(
    "SHELL_UTILS_SCRIPTS_PATH=$BATS_TEST_DIRNAME/../scripts"
    "SHELL_UTILS_SCRIPT_DIRNAME=$BATS_TEST_DIRNAME/../scripts/backup.bkp/remote.rmt"
    "SHELL_UTILS_BACKUP_ENCRYPT_PASSWORD=test-password"
    "SHELL_UTILS_BACKUP_RCLONE_REMOTE=remote"
    "SHELL_UTILS_BACKUP_RCLONE_FOLDER=backups"
    "SHELL_UTILS_REMOTE_UNWRAP_DEST=$TEST_ROOT/destination"
    "RCLONE_ARGS=$TEST_ROOT/rclone.args"
    "OPENSSL_ARGS=$TEST_ROOT/openssl.args"
    "UNZIP_ARGS=$TEST_ROOT/unzip.args"
    "RCLONE_DEST=$TEST_ROOT/destination"
    "RCLONE_OUTPUT=${RCLONE_OUTPUT:-}"
    "PATH=$TEST_ROOT/bin:$PATH"
  )
}

run_unwrap() {
  run env \
    "${UNWRAP_ENV[@]}" \
    bash "$BATS_TEST_DIRNAME/../scripts/backup.bkp/remote.rmt/unwrap.uwr.sh" "$@"
}

@test "rejects multiple backup file arguments" {
  run_unwrap first.zip.enc second.zip.enc

  [[ "$status" -eq 1 ]]
}

@test "downloads, decrypts, and unzips a selected backup" {
  run_unwrap backup_20260101000000.zip.enc

  [[ "$status" -eq 0 ]]
  mapfile -d '' rclone_args <"$TEST_ROOT/rclone.args"
  [[ "${rclone_args[*]}" == "copy remote:backups/backup_20260101000000.zip.enc $TEST_ROOT/destination" ]]
  mapfile -d '' openssl_args <"$TEST_ROOT/openssl.args"
  [[ "${openssl_args[*]}" == "enc -d -aes-256-cbc -pbkdf2 -iter 100000 -salt -in $TEST_ROOT/destination/backup_20260101000000.zip.enc -out $TEST_ROOT/destination/backup_20260101000000.zip -pass env:SHELL_UTILS_BACKUP_ENCRYPT_PASSWORD" ]]
  mapfile -d '' unzip_args <"$TEST_ROOT/unzip.args"
  [[ "${unzip_args[*]}" == "-q $TEST_ROOT/destination/backup_20260101000000.zip -d $TEST_ROOT/destination/backup_20260101000000" ]]
}

@test "fetches the first latest backup listing" {
  # shellcheck disable=SC2030
  UNWRAP_ENV+=(
    "RCLONE_OUTPUT=backup_20260101000000.zip.enc"
  )
  run_unwrap --latest

  [[ "$status" -eq 0 ]]
  mapfile -d '' rclone_args <"$TEST_ROOT/rclone.args"
  [[ "${rclone_args[*]}" == *"ls remote:backups copy remote:backups/backup_20260101000000.zip.enc $TEST_ROOT/destination"* ]]
}

@test "rejects a file together with --latest" {
  run_unwrap --latest backup_20260101000000.zip.enc

  [[ "$status" -eq 1 ]]
}

@test "requires a file when --latest is absent" {
  run_unwrap

  [[ "$status" -eq 1 ]]
}

@test "fails when the encryption password is missing" {
  # shellcheck disable=SC2030,SC2031
  UNWRAP_ENV+=(
    "SHELL_UTILS_BACKUP_ENCRYPT_PASSWORD="
  )
  run_unwrap backup.zip.enc

  [[ "$status" -eq 1 ]]
}

@test "fails when rclone is unavailable" {
  mkdir "$TEST_ROOT/failing-bin"
  ln -s "$TEST_ROOT/bin/failing-rclone" "$TEST_ROOT/failing-bin/rclone"

  # shellcheck disable=SC2031
  UNWRAP_ENV+=(
    "PATH=$TEST_ROOT/failing-bin:$PATH"
  )
  run_unwrap backup.zip.enc

  [[ "$status" -eq 9 ]]
}
