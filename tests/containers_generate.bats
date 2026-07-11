#!/usr/bin/env bats

load test_helper

setup() {
  # shellcheck disable=SC2154
  TEST_ROOT="$BATS_TEST_TMPDIR/containers-generate"
  mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/home/.shell-utils/containers" \
    "$TEST_ROOT/mock-args"
  MOCK_OUTPUT_DIR="$TEST_ROOT/mock-output"
  MOCK_STATUS_DIR="$TEST_ROOT/mock-status"
  mkdir -p "$MOCK_OUTPUT_DIR" "$MOCK_STATUS_DIR"
  mock_whoami "$TEST_ROOT/bin"
  mock_fallocate "$TEST_ROOT/bin"
  mock_cryptsetup "$TEST_ROOT/bin"
  mock_date "$TEST_ROOT/bin"
  mock_sudo "$TEST_ROOT/bin"
  mock_mkfs_ext4 "$TEST_ROOT/bin"
  mock_mount "$TEST_ROOT/bin"
  mock_chown "$TEST_ROOT/bin"
  mock_umount "$TEST_ROOT/bin"
  printf '20260101000000\n' >"$MOCK_OUTPUT_DIR/date"
  printf 'bats-test-user\n' >"$MOCK_OUTPUT_DIR/whoami"

  # shellcheck disable=SC2154
  GENERATE_ENV=(
    "SHELL_UTILS_SCRIPTS_PATH=$BATS_TEST_DIRNAME/../scripts"
    "SHELL_UTILS_SCRIPT_DIRNAME=$BATS_TEST_DIRNAME/../scripts/containers.cnt"
    "HOME=$TEST_ROOT/home"
    "MOCK_ARGS_DIR=$TEST_ROOT/mock-args"
    "MOCK_OUTPUT_DIR=$MOCK_OUTPUT_DIR"
    "MOCK_STATUS_DIR=$MOCK_STATUS_DIR"
    "PATH=$TEST_ROOT/bin:$PATH"
  )
}

run_generate() {
  run env "${GENERATE_ENV[@]}" \
    bash "$BATS_TEST_DIRNAME/../scripts/containers.cnt/generate.gnr.sh" "$@"
}

@test 'fails when name is missing' {
  run_generate

  [[ "$status" -eq 1 ]]
}

@test 'fails when size is missing' {
  run_generate projects

  [[ "$status" -eq 1 ]]
}

@test 'rejects unsupported filesystems' {
  run_generate --filesystem btrfs projects 2G

  [[ "$status" -eq 1 ]]
}

@test 'creates an ext4 container with the expected workflow' {
  run_generate --filesystem ext4 projects 2G

  [[ "$status" -eq 0 ]]
  mapfile -d '' fallocate_args <"$TEST_ROOT/mock-args/fallocate.args"
  [[ "${fallocate_args[*]}" == "-l 2G $TEST_ROOT/home/.shell-utils/containers/projects.img" ]]
  mapfile -d '' cryptsetup_args <"$TEST_ROOT/mock-args/cryptsetup.args"
  [[ "${cryptsetup_args[*]}" == *"luksFormat $TEST_ROOT/home/.shell-utils/containers/projects.img"* ]]
  [[ "${cryptsetup_args[*]}" == *"luksOpen $TEST_ROOT/home/.shell-utils/containers/projects.img container-20260101000000"* ]]
  [[ "${cryptsetup_args[*]}" == *"luksClose container-20260101000000"* ]]
  mapfile -d '' mount_args <"$TEST_ROOT/mock-args/mount.args"
  [[ "${mount_args[*]}" == "/dev/mapper/container-20260101000000 /mnt" ]]
  mapfile -d '' umount_args <"$TEST_ROOT/mock-args/umount.args"
  [[ "${umount_args[*]}" == "/mnt" ]]
}
