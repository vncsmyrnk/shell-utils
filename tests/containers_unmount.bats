#!/usr/bin/env bats

load test_helper

setup() {
  # shellcheck disable=SC2154
  TEST_ROOT="$BATS_TEST_TMPDIR/containers-unmount"
  mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/home/.shell-utils/containers" \
    "$TEST_ROOT/mock-args" "$TEST_ROOT/mock-output" "$TEST_ROOT/mock-status" \
    "$TEST_ROOT/mounts/projects"
  mock_losetup "$TEST_ROOT/bin"
  mock_lsblk "$TEST_ROOT/bin"
  mock_fuser "$TEST_ROOT/bin"
  mock_sudo "$TEST_ROOT/bin"
  mock_umount "$TEST_ROOT/bin"
  mock_cryptsetup "$TEST_ROOT/bin"
  : >"$TEST_ROOT/home/.shell-utils/containers/projects.img"
  printf '/dev/loop7\n' >"$TEST_ROOT/mock-output/losetup"
  printf '%s\n' "$TEST_ROOT/mounts/projects" >"$TEST_ROOT/mock-output/lsblk"
  printf '1\n' >"$TEST_ROOT/mock-status/fuser"

  # shellcheck disable=SC2154
  UNMOUNT_ENV=(
    "SHELL_UTILS_SCRIPTS_PATH=$BATS_TEST_DIRNAME/../scripts"
    "SHELL_UTILS_SCRIPT_DIRNAME=$BATS_TEST_DIRNAME/../scripts/containers.cnt"
    "HOME=$TEST_ROOT/home"
    "MOCK_ARGS_DIR=$TEST_ROOT/mock-args"
    "MOCK_OUTPUT_DIR=$TEST_ROOT/mock-output"
    "MOCK_STATUS_DIR=$TEST_ROOT/mock-status"
    "PATH=$TEST_ROOT/bin:$PATH"
  )
}

run_unmount() {
  run env "${UNMOUNT_ENV[@]}" \
    bash "$BATS_TEST_DIRNAME/../scripts/containers.cnt/unmount.umnt.sh" "$@"
}

@test 'fails when a container file is missing' {
  run_unmount missing

  [[ "$status" -eq 1 ]]
}

@test 'fails when the container is not mounted' {
  : >"$TEST_ROOT/mock-output/losetup"

  run_unmount projects

  [[ "$status" -eq 1 ]]
}

@test 'unmounts an idle container and removes its target' {
  run_unmount projects

  [[ "$status" -eq 0 ]]
  [[ ! -d "$TEST_ROOT/mounts/projects" ]]
  mapfile -d '' umount_args <"$TEST_ROOT/mock-args/umount.args"
  [[ "${umount_args[*]}" == "$TEST_ROOT/mounts/projects" ]]
  mapfile -d '' cryptsetup_args <"$TEST_ROOT/mock-args/cryptsetup.args"
  [[ "${cryptsetup_args[*]}" == "close container_projects" ]]
}

@test 'refuses to kill a busy container without confirmation' {
  printf '0\n' >"$TEST_ROOT/mock-status/fuser"

  run_unmount projects <<<"n"

  [[ "$status" -eq 1 ]]
  [[ -d "$TEST_ROOT/mounts/projects" ]]
}

@test 'force kills busy processes before unmounting' {
  printf '0\n' >"$TEST_ROOT/mock-status/fuser"

  run_unmount --force projects

  [[ "$status" -eq 0 ]]
  mapfile -d '' fuser_args <"$TEST_ROOT/mock-args/fuser.args"
  [[ "${fuser_args[*]}" == *"-k"* ]]
  [[ ! -d "$TEST_ROOT/mounts/projects" ]]
}
