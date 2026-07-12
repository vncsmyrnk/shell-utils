#!/usr/bin/env bats

load test_helper

setup() {
  # shellcheck disable=SC2154
  TEST_ROOT="$BATS_TEST_TMPDIR/environment-edit"
  mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/home" \
    "$TEST_ROOT/mock-args" "$TEST_ROOT/mock-output" \
    "$TEST_ROOT/mock-status"
  mock_sops "$TEST_ROOT/bin"

  # shellcheck disable=SC2154
  EDIT_ENV=(
    "SHELL_UTILS_SCRIPT_DIRNAME=$BATS_TEST_DIRNAME/../scripts/environment.env"
    "HOME=$TEST_ROOT/home"
    "MOCK_ARGS_DIR=$TEST_ROOT/mock-args"
    "MOCK_OUTPUT_DIR=$TEST_ROOT/mock-output"
    "MOCK_STATUS_DIR=$TEST_ROOT/mock-status"
    "PATH=$TEST_ROOT/bin:$PATH"
  )
}

run_environment_edit() {
  run env "${EDIT_ENV[@]}" \
    bash "$BATS_TEST_DIRNAME/../scripts/environment.env/edit.sh" "$@"
}

@test 'uses the default secret path' {
  run_environment_edit

  [[ "$status" -eq 0 ]]
  default_secret_path="$TEST_ROOT/home/.config/shell-utils/environment/default.env"
  mapfile -d '' sops_args <"$TEST_ROOT/mock-args/sops.args"
  [[ "${sops_args[0]}" == "$default_secret_path" ]]
}

@test 'uses an explicit secret path with -f' {
  secret_file="$TEST_ROOT/custom.env"

  run_environment_edit -f "$secret_file"

  [[ "$status" -eq 0 ]]
  mapfile -d '' sops_args <"$TEST_ROOT/mock-args/sops.args"
  [[ "${sops_args[0]}" == "$secret_file" ]]
}

@test 'uses an explicit secret path with --file' {
  secret_file="$TEST_ROOT/long-option.env"

  run_environment_edit --file "$secret_file"

  [[ "$status" -eq 0 ]]
  mapfile -d '' sops_args <"$TEST_ROOT/mock-args/sops.args"
  [[ "${sops_args[0]}" == "$secret_file" ]]
}

@test 'propagates a sops failure' {
  printf '9\n' >"$TEST_ROOT/mock-status/sops"

  run_environment_edit

  [[ "$status" -eq 9 ]]
}
