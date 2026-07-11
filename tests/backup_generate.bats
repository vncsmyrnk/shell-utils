#!/usr/bin/env bats

setup() {
  # shellcheck disable=SC2154
  TEST_ROOT="$BATS_TEST_TMPDIR/backup-generate"
  mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/source" "$TEST_ROOT/output"
  printf 'fixture\n' >"$TEST_ROOT/source/file.txt"

  printf '#!%s\n' "$(command -v bash || true)" >"$TEST_ROOT/bin/date"
  cat >>"$TEST_ROOT/bin/date" <<'EOF'
printf '20260101000000\n'
EOF
  printf '#!%s\n' "$(command -v bash || true)" >"$TEST_ROOT/bin/zip"
  cat >>"$TEST_ROOT/bin/zip" <<'EOF'
printf '%s\0' "$@" >>"$ZIP_ARGS"
for ((index = 1; index <= $#; index++)); do
  if [[ "${!index}" != -* ]]; then
    : >"${!index}"
    break
  fi
done
EOF
  printf '#!%s\n' "$(command -v bash || true)" >"$TEST_ROOT/bin/openssl"
  cat >>"$TEST_ROOT/bin/openssl" <<'EOF'
printf '%s\0' "$@" >"$OPENSSL_ARGS"
for ((index = 1; index <= $#; index++)); do
  if [[ "${!index}" == "-out" ]]; then
    output_index=$((index + 1))
    : >"${!output_index}"
    break
  fi
done
EOF
  printf '#!%s\n' "$(command -v bash || true)" >"$TEST_ROOT/bin/rclone"
  cat >>"$TEST_ROOT/bin/rclone" <<'EOF'
printf '%s\n' "$*" >>"$RCLONE_LOG"
EOF
  printf '#!%s\n' "$(command -v bash || true)" >"$TEST_ROOT/bin/failing-zip"
  cat >>"$TEST_ROOT/bin/failing-zip" <<'EOF'
printf 'zip failed\n' >&2
exit 7
EOF
  printf '#!%s\n' "$(command -v bash || true)" >"$TEST_ROOT/bin/failing-openssl"
  cat >>"$TEST_ROOT/bin/failing-openssl" <<'EOF'
printf 'openssl failed\n' >&2
exit 9
EOF
  chmod +x "$TEST_ROOT/bin/"*

  # shellcheck disable=SC2154
  GENERATE_ENV=(
    "SHELL_UTILS_SCRIPTS_PATH=$BATS_TEST_DIRNAME/../scripts"
    "SHELL_UTILS_SCRIPT_DIRNAME=$BATS_TEST_DIRNAME/../scripts/backup.bkp"
    "SHELL_UTILS_BKP_PATHS=$TEST_ROOT/source/file.txt"
    "SHELL_UTILS_BACKUP_ZIP_DIR=$TEST_ROOT/output"
    "SHELL_UTILS_BACKUP_ENCRYPTED_DIR=$TEST_ROOT/output"
    "PATH=$TEST_ROOT/bin:$PATH"
    "SHELL_UTILS_BACKUP_ENCRYPT_PASSWORD=test-password"
    "SHELL_UTILS_BACKUP_RCLONE_REMOTE="
    "SHELL_UTILS_BACKUP_RCLONE_FOLDER="
    "ZIP_ARGS=$TEST_ROOT/zip.args"
    "OPENSSL_ARGS=$TEST_ROOT/openssl.args"
    "RCLONE_LOG=$TEST_ROOT/rclone.log"
  )
}

run_generate() {
  # shellcheck disable=SC2154
  run env \
    "${GENERATE_ENV[@]}" \
    bash "$BATS_TEST_DIRNAME/../scripts/backup.bkp/generate.gen.sh" "$@"
}

@test "fails when the encryption password is missing" {
  # shellcheck disable=SC2030
  GENERATE_ENV+=(
    "SHELL_UTILS_BACKUP_ENCRYPT_PASSWORD="
  )
  run_generate --bypass-password

  [[ "$status" -eq 1 ]]
}

@test "propagates compression failure" {
  mkdir "$TEST_ROOT/failing-bin"
  ln -s "$TEST_ROOT/bin/failing-zip" "$TEST_ROOT/failing-bin/zip"

  # shellcheck disable=SC2030,SC2031
  GENERATE_ENV+=(
    "PATH=$TEST_ROOT/failing-bin:$TEST_ROOT/bin:$PATH"
  )
  run_generate --bypass-password

  [[ "$status" -eq 1 ]]
}

@test "propagates encryption failure" {
  mkdir "$TEST_ROOT/failing-bin"
  ln -s "$TEST_ROOT/bin/failing-openssl" "$TEST_ROOT/failing-bin/openssl"

  # shellcheck disable=SC2030,SC2031
  GENERATE_ENV+=(
    "PATH=$TEST_ROOT/failing-bin:$TEST_ROOT/bin:$PATH"
  )
  run_generate --bypass-password

  [[ "$status" -eq 1 ]]
}

@test "creates an encrypted backup without asking for confirmation when bypassed" {
  run_generate --bypass-password

  [[ "$status" -eq 0 ]]
  [[ -f "$TEST_ROOT/output/backup_20260101000000.zip" ]]
  [[ -f "$TEST_ROOT/output/backup_20260101000000.zip.enc" ]]
}

@test "uses the required zip arguments" {
  run_generate --bypass-password

  mapfile -d '' zip_args <"$TEST_ROOT/zip.args"
  [[ "${zip_args[*]}" == "-q $TEST_ROOT/output/backup_20260101000000.zip $TEST_ROOT/source/file.txt -T $TEST_ROOT/output/backup_20260101000000.zip" ]]
}

@test "uses the required openssl encryption arguments" {
  run_generate --bypass-password

  mapfile -d '' openssl_args <"$TEST_ROOT/openssl.args"
  [[ "${openssl_args[*]}" == "enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -in $TEST_ROOT/output/backup_20260101000000.zip -out $TEST_ROOT/output/backup_20260101000000.zip.enc -pass env:SHELL_UTILS_BACKUP_ENCRYPT_PASSWORD" ]]
}

@test "uploads the encrypted backup when rclone is configured" {
  # shellcheck disable=SC2031,SC2030
  GENERATE_ENV+=(
    "SHELL_UTILS_BACKUP_RCLONE_REMOTE=remote"
    "SHELL_UTILS_BACKUP_RCLONE_FOLDER=backups"
    "SHELL_UTILS_BACKUP_ENCRYPT_PASSWORD=password"
  )
  run_generate < <(
    echo 'password'
  )

  [[ "$status" -eq 0 ]]
  grep -Fq "copy -v $TEST_ROOT/output/backup_20260101000000.zip.enc remote:backups" "$TEST_ROOT/rclone.log"
}

@test "rejects a mismatched encryption password confirmation" {
  # shellcheck disable=SC2031
  GENERATE_ENV+=(
    "SHELL_UTILS_BACKUP_ENCRYPT_PASSWORD=password"
  )
  # shellcheck disable=SC2312
  run_generate < <(
    echo 'wrong-password'
  )

  [[ "$status" -eq 1 ]]
}
