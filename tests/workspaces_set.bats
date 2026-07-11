#!/usr/bin/env bats

load test_helper

setup() {
  # shellcheck disable=SC2154
  TEST_ROOT="$BATS_TEST_TMPDIR/workspaces-set"
  mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/home/.shell-utils/workspaces" \
    "$TEST_ROOT/home/.config/shell-utils/workspaces" "$TEST_ROOT/mock-args" \
    "$TEST_ROOT/mock-output" "$TEST_ROOT/mock-status"
  mock_whoami "$TEST_ROOT/bin"
  mock_losetup "$TEST_ROOT/bin"
  mock_lsblk "$TEST_ROOT/bin"
  mock_sudo "$TEST_ROOT/bin"
  mock_cryptsetup "$TEST_ROOT/bin"
  mock_mkdir "$TEST_ROOT/bin"
  mock_mount "$TEST_ROOT/bin"
  mock_jq "$TEST_ROOT/bin"
  mock_envsubst "$TEST_ROOT/bin"
  mock_stow "$TEST_ROOT/bin"
  mock_find "$TEST_ROOT/bin"
  mock_ssh_add "$TEST_ROOT/bin"
  mock_fuser "$TEST_ROOT/bin"
  mock_umount "$TEST_ROOT/bin"
  : >"$TEST_ROOT/home/.shell-utils/workspaces/default.img"
  printf '{"removeBeforeStow":[]}\n' \
    >"$TEST_ROOT/home/.config/shell-utils/workspaces/default.json"
  : >"$TEST_ROOT/mock-output/losetup"
  printf 'bats-test-user\n' >"$TEST_ROOT/mock-output/whoami"
  printf '%s/.ssh/id_ed25519\n' "$TEST_ROOT/home" \
    >"$TEST_ROOT/mock-output/find"
  printf '1\n' >"$TEST_ROOT/mock-status/fuser"

  # shellcheck disable=SC2154
  SET_ENV=(
    "SHELL_UTILS_SCRIPTS_PATH=$BATS_TEST_DIRNAME/../scripts"
    "SHELL_UTILS_SCRIPT_DIRNAME=$BATS_TEST_DIRNAME/../scripts/workspaces.ws"
    "HOME=$TEST_ROOT/home"
    "MOCK_ARGS_DIR=$TEST_ROOT/mock-args"
    "MOCK_OUTPUT_DIR=$TEST_ROOT/mock-output"
    "MOCK_STATUS_DIR=$TEST_ROOT/mock-status"
    "PATH=$TEST_ROOT/bin:$PATH"
  )
}

run_workspace_set() {
  run env "${SET_ENV[@]}" \
    bash "$BATS_TEST_DIRNAME/../scripts/workspaces.ws/set.sh" "$@"
}

@test 'uses the default workspace and stows its contents' {
  run_workspace_set

  [[ "$status" -eq 0 ]]
  mapfile -d '' cryptsetup_args <"$TEST_ROOT/mock-args/cryptsetup.args"
  [[ "${cryptsetup_args[*]}" == *"open $TEST_ROOT/home/.shell-utils/workspaces/default.img default"* ]]
  mapfile -d '' stow_args <"$TEST_ROOT/mock-args/stow.args"
  [[ "${stow_args[*]}" == "-d /tmp/shell-utils.bats-test-user/default -t $TEST_ROOT/home ." ]]
  mapfile -d '' ssh_add_args <"$TEST_ROOT/mock-args/ssh-add.args"
  [[ "${ssh_add_args[*]}" == "$TEST_ROOT/home/.ssh/id_ed25519" ]]
}

@test 'preserves an explicit workspace image' {
  : >"$TEST_ROOT/explicit.img"

  run_workspace_set "$TEST_ROOT/explicit.img"

  [[ "$status" -eq 0 ]]
  mapfile -d '' cryptsetup_args <"$TEST_ROOT/mock-args/cryptsetup.args"
  [[ "${cryptsetup_args[*]}" == *"open $TEST_ROOT/explicit.img explicit"* ]]
}

@test 'declines removal of a conflicting path and unmounts' {
  conflict="$TEST_ROOT/home/.config/conflict"
  mkdir -p "$conflict"
  printf '%s\n' "$conflict" >"$TEST_ROOT/mock-output/jq"

  run_workspace_set <<<"n"

  [[ "$status" -eq 1 ]]
  [[ -d "$conflict" ]]
  mapfile -d '' umount_args <"$TEST_ROOT/mock-args/umount.args"
  [[ "${umount_args[*]}" == /tmp/shell-utils.bats-test-user/default ]]
}

@test 'removes a confirmed conflict before stowing' {
  conflict="$TEST_ROOT/home/.config/conflict"
  mkdir -p "$conflict"
  printf '%s\n' "$conflict" >"$TEST_ROOT/mock-output/jq"

  run_workspace_set <<<"y"

  [[ "$status" -eq 0 ]]
  [[ ! -e "$conflict" ]]
}

@test 'unmounts after stow fails' {
  printf '7\n' >"$TEST_ROOT/mock-status/stow"

  run_workspace_set

  [[ "$status" -eq 1 ]]
  mapfile -d '' cryptsetup_args <"$TEST_ROOT/mock-args/cryptsetup.args"
  [[ "${cryptsetup_args[*]}" == *"close default"* ]]
}
