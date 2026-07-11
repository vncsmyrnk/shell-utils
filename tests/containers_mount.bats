#!/usr/bin/env bats

load test_helper

setup() {
  # shellcheck disable=SC2154
  TEST_ROOT="$BATS_TEST_TMPDIR/containers-mount"
  mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/home/.shell-utils/containers" \
    "$TEST_ROOT/home/.config/shell-utils/containers" "$TEST_ROOT/mock-args" \
    "$TEST_ROOT/mock-output" "$TEST_ROOT/mock-status"
  mock_jq "$TEST_ROOT/bin"
  mock_envsubst "$TEST_ROOT/bin"
  mock_losetup "$TEST_ROOT/bin"
  mock_lsblk "$TEST_ROOT/bin"
  mock_sudo "$TEST_ROOT/bin"
  mock_cryptsetup "$TEST_ROOT/bin"
  mock_mkdir "$TEST_ROOT/bin"
  mock_mount "$TEST_ROOT/bin"
  : >"$TEST_ROOT/home/.shell-utils/containers/projects.img"
  printf '{"mountpoint":"%s"}\n' "$TEST_ROOT/target" \
    >"$TEST_ROOT/home/.config/shell-utils/containers/projects.json"
  : >"$TEST_ROOT/explicit.img"
  printf '%s\n' "$TEST_ROOT/target" >"$TEST_ROOT/mock-output/jq"

  # shellcheck disable=SC2154
  MOUNT_ENV=(
    "SHELL_UTILS_SCRIPTS_PATH=$BATS_TEST_DIRNAME/../scripts"
    "SHELL_UTILS_SCRIPT_DIRNAME=$BATS_TEST_DIRNAME/../scripts/containers.cnt"
    "HOME=$TEST_ROOT/home"
    "MOCK_ARGS_DIR=$TEST_ROOT/mock-args"
    "MOCK_OUTPUT_DIR=$TEST_ROOT/mock-output"
    "MOCK_STATUS_DIR=$TEST_ROOT/mock-status"
    "PATH=$TEST_ROOT/bin:$PATH"
  )
}

run_mount() {
  run env "${MOUNT_ENV[@]}" \
    bash "$BATS_TEST_DIRNAME/../scripts/containers.cnt/mount.mnt.sh" "$@"
}

@test 'fails when a named container file is missing' {
  run_mount missing

  [[ "$status" -eq 1 ]]
}

@test 'fails when an explicit image has no target' {
  run_mount "$TEST_ROOT/explicit.img"

  [[ "$status" -eq 1 ]]
}

@test 'mounts a named container using its configuration' {
  run_mount projects

  [[ "$status" -eq 0 ]]
  mapfile -d '' cryptsetup_args <"$TEST_ROOT/mock-args/cryptsetup.args"
  [[ "${cryptsetup_args[*]}" == *"open $TEST_ROOT/home/.shell-utils/containers/projects.img container_projects"* ]]
  mapfile -d '' mount_args <"$TEST_ROOT/mock-args/mount.args"
  [[ "${mount_args[*]}" == "/dev/mapper/container_projects $TEST_ROOT/target" ]]
}

@test 'rejects an already mounted container' {
  printf '%s\n' "$TEST_ROOT/loop7" >"$TEST_ROOT/mock-output/losetup"
  printf '%s\n' "$TEST_ROOT/target" >"$TEST_ROOT/mock-output/lsblk"

  run_mount projects

  [[ "$status" -eq 1 ]]
}

@test 'closes the mapper when mounting fails' {
  printf '7\n' >"$TEST_ROOT/mock-status/mount"

  run_mount projects

  [[ "$status" -eq 1 ]]
  mapfile -d '' cryptsetup_args <"$TEST_ROOT/mock-args/cryptsetup.args"
  [[ "${cryptsetup_args[*]}" == *"close container_projects"* ]]
}
