#!/usr/bin/env bats

load test_helper

setup() {
  # shellcheck disable=SC2154
  TEST_ROOT="$BATS_TEST_TMPDIR/workspaces-list"
  mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/home" "$TEST_ROOT/mock-args" \
    "$TEST_ROOT/mock-output" "$TEST_ROOT/mock-status"
  mock_whoami "$TEST_ROOT/bin"
  mock_lsblk "$TEST_ROOT/bin"
  mock_losetup "$TEST_ROOT/bin"
  mock_column "$TEST_ROOT/bin"
  printf 'bats-test-user\n' >"$TEST_ROOT/mock-output/whoami"
  printf '/dev/loop8 5G 10G 50%%\n' >"$TEST_ROOT/mock-output/lsblk"
  printf '%s\n' "$TEST_ROOT/home/.shell-utils/workspaces/default.img" \
    >"$TEST_ROOT/mock-output/losetup"

  # shellcheck disable=SC2154
  LIST_ENV=(
    "SHELL_UTILS_SCRIPT_DIRNAME=$BATS_TEST_DIRNAME/../scripts/workspaces.ws"
    "HOME=$TEST_ROOT/home"
    "MOCK_ARGS_DIR=$TEST_ROOT/mock-args"
    "MOCK_OUTPUT_DIR=$TEST_ROOT/mock-output"
    "MOCK_STATUS_DIR=$TEST_ROOT/mock-status"
    "PATH=$TEST_ROOT/bin:$PATH"
  )
}

run_workspaces_list() {
  run env "${LIST_ENV[@]}" \
    bash "$BATS_TEST_DIRNAME/../scripts/workspaces.ws/list.ls.sh" "$@"
}

@test 'fails when no active workspace exists' {
  : >"$TEST_ROOT/mock-output/lsblk"

  run_workspaces_list

  [[ "$status" -eq 1 ]]
  [[ "$output" == *'no active workspace found.'* ]]
}

@test 'lists a workspace with a heading by default' {
  run_workspaces_list

  [[ "$status" -eq 0 ]]
  [[ "$output" == *'FILE USED SIZE USAGE'* ]]
  [[ "$output" == *'default.img 5G 10G 50%'* ]]
}

@test 'hides workspace headings when requested' {
  run_workspaces_list --noheadings

  [[ "$status" -eq 0 ]]
  [[ "$output" != *'FILE USED SIZE USAGE'* ]]
  [[ "$output" == *'default.img 5G 10G 50%'* ]]
}
