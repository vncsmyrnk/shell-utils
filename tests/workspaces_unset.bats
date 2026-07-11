#!/usr/bin/env bats

load test_helper

setup() {
  # shellcheck disable=SC2154
  TEST_ROOT="$BATS_TEST_TMPDIR/workspaces-unset"
  mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/home/.shell-utils/workspaces" \
    "$TEST_ROOT/mock-args" "$TEST_ROOT/mock-output" "$TEST_ROOT/mock-status"
  mock_whoami "$TEST_ROOT/bin"
  mock_losetup "$TEST_ROOT/bin"
  mock_lsblk "$TEST_ROOT/bin"
  mock_fuser "$TEST_ROOT/bin"
  mock_stow "$TEST_ROOT/bin"
  mock_sudo "$TEST_ROOT/bin"
  mock_umount "$TEST_ROOT/bin"
  mock_cryptsetup "$TEST_ROOT/bin"
  mock_ssh_add "$TEST_ROOT/bin"
  : >"$TEST_ROOT/home/.shell-utils/workspaces/default.img"
  printf 'bats-test-user\n' >"$TEST_ROOT/mock-output/whoami"
  printf '/dev/loop8\n' >"$TEST_ROOT/mock-output/losetup"
  printf '/tmp/shell-utils.bats-test-user/default\n' \
    >"$TEST_ROOT/mock-output/lsblk"
  printf '1\n' >"$TEST_ROOT/mock-status/fuser"

  # shellcheck disable=SC2154
  UNSET_ENV=(
    "SHELL_UTILS_SCRIPTS_PATH=$BATS_TEST_DIRNAME/../scripts"
    "SHELL_UTILS_SCRIPT_DIRNAME=$BATS_TEST_DIRNAME/../scripts/workspaces.ws"
    "HOME=$TEST_ROOT/home"
    "MOCK_ARGS_DIR=$TEST_ROOT/mock-args"
    "MOCK_OUTPUT_DIR=$TEST_ROOT/mock-output"
    "MOCK_STATUS_DIR=$TEST_ROOT/mock-status"
    "PATH=$TEST_ROOT/bin:$PATH"
  )
}

run_workspace_unset() {
  run env "${UNSET_ENV[@]}" \
    bash "$BATS_TEST_DIRNAME/../scripts/workspaces.ws/unset.sh" "$@"
}

@test 'fails when the default workspace is missing' {
  rm "$TEST_ROOT/home/.shell-utils/workspaces/default.img"

  run_workspace_unset

  [[ "$status" -eq 1 ]]
}

@test 'fails when an explicit workspace is not mounted' {
  : >"$TEST_ROOT/explicit.img"
  : >"$TEST_ROOT/mock-output/losetup"

  run_workspace_unset "$TEST_ROOT/explicit.img"

  [[ "$status" -eq 1 ]]
}

@test 'unstows and unmounts the default workspace' {
  run_workspace_unset

  [[ "$status" -eq 0 ]]
  mapfile -d '' stow_args <"$TEST_ROOT/mock-args/stow.args"
  [[ "${stow_args[*]}" == "-D -d /tmp/shell-utils.bats-test-user/default -t $TEST_ROOT/home ." ]]
  mapfile -d '' cryptsetup_args <"$TEST_ROOT/mock-args/cryptsetup.args"
  [[ "${cryptsetup_args[*]}" == "close default" ]]
  mapfile -d '' ssh_add_args <"$TEST_ROOT/mock-args/ssh-add.args"
  [[ "${ssh_add_args[*]}" == "-D" ]]
}

@test 'refuses to kill a busy workspace without confirmation' {
  printf '0\n' >"$TEST_ROOT/mock-status/fuser"

  run_workspace_unset <<<"n"

  [[ "$status" -eq 1 ]]
  [[ ! -f "$TEST_ROOT/mock-args/stow.args" ]]
}

@test 'force kills busy processes before unstowing' {
  printf '0\n' >"$TEST_ROOT/mock-status/fuser"

  run_workspace_unset --force

  [[ "$status" -eq 0 ]]
  mapfile -d '' fuser_args <"$TEST_ROOT/mock-args/fuser.args"
  [[ "${fuser_args[*]}" == *"-k"* ]]
  [[ -f "$TEST_ROOT/mock-args/stow.args" ]]
}
