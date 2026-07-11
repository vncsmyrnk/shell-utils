#!/usr/bin/env bats

load test_helper

setup() {
  # shellcheck disable=SC2154
  TEST_ROOT="$BATS_TEST_TMPDIR/containers-list"
  mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/home/.config/shell-utils/containers" \
    "$TEST_ROOT/mock-args" "$TEST_ROOT/mock-output" "$TEST_ROOT/mock-status"
  mock_lsblk "$TEST_ROOT/bin"
  mock_losetup "$TEST_ROOT/bin"
  mock_column "$TEST_ROOT/bin"
  printf 'projects\n' >"$TEST_ROOT/home/.config/shell-utils/containers/projects.json"
  printf '/dev/loop7 /mnt/projects 10G 20G 50%%\n' \
    >"$TEST_ROOT/mock-output/lsblk"
  printf '%s\n' "$TEST_ROOT/home/.shell-utils/containers/projects.img" \
    >"$TEST_ROOT/mock-output/losetup"

  # shellcheck disable=SC2154
  LIST_ENV=(
    "SHELL_UTILS_SCRIPTS_PATH=$BATS_TEST_DIRNAME/../scripts"
    "SHELL_UTILS_SCRIPT_DIRNAME=$BATS_TEST_DIRNAME/../scripts/containers.cnt"
    "HOME=$TEST_ROOT/home"
    "MOCK_ARGS_DIR=$TEST_ROOT/mock-args"
    "MOCK_OUTPUT_DIR=$TEST_ROOT/mock-output"
    "MOCK_STATUS_DIR=$TEST_ROOT/mock-status"
    "PATH=$TEST_ROOT/bin:$PATH"
  )
}

run_containers_list() {
  run env "${LIST_ENV[@]}" \
    bash "$BATS_TEST_DIRNAME/../scripts/containers.cnt/list.ls.sh" "$@"
}

@test 'fails when no active container exists' {
  : >"$TEST_ROOT/mock-output/lsblk"

  run_containers_list

  [[ "$status" -eq 1 ]]
  [[ "$output" == *'no active container found.'* ]]
}

@test 'lists a container with a heading by default' {
  run_containers_list

  [[ "$status" -eq 0 ]]
  [[ "$output" == *'FILE MOUNTPOINT USED SIZE USAGE'* ]]
  [[ "$output" == *'projects /mnt/projects 10G 20G 50%'* ]]
}

@test 'hides headings when requested' {
  run_containers_list --noheadings

  [[ "$status" -eq 0 ]]
  [[ "$output" != *'FILE MOUNTPOINT USED SIZE USAGE'* ]]
  [[ "$output" == *'projects /mnt/projects 10G 20G 50%'* ]]
}

@test 'shows the full backing path when requested' {
  run_containers_list --full-path

  [[ "$status" -eq 0 ]]
  [[ "$output" == *"$TEST_ROOT/home/.shell-utils/containers/projects.img"* ]]
}
