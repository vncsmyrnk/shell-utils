#!/usr/bin/env bats

load test_helper

setup() {
  # shellcheck disable=SC2154
  TEST_ROOT="$BATS_TEST_TMPDIR/environment-exec"
  mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/home" \
    "$TEST_ROOT/mock-args" "$TEST_ROOT/mock-output" \
    "$TEST_ROOT/mock-status"
  mock_sops "$TEST_ROOT/bin"

  # shellcheck disable=SC2154
  EXEC_ENV=(
    "SHELL_UTILS_SCRIPTS_PATH=$BATS_TEST_DIRNAME/../scripts"
    "SHELL_UTILS_SCRIPT_DIRNAME=$BATS_TEST_DIRNAME/../scripts/environment.env"
    "HOME=$TEST_ROOT/home"
    "MOCK_ARGS_DIR=$TEST_ROOT/mock-args"
    "MOCK_OUTPUT_DIR=$TEST_ROOT/mock-output"
    "MOCK_STATUS_DIR=$TEST_ROOT/mock-status"
    "PATH=$TEST_ROOT/bin:$PATH"
  )
}

run_environment_exec() {
  run env "${EXEC_ENV[@]}" \
    bash "$BATS_TEST_DIRNAME/../scripts/environment.env/exec.sh" "$@"
}

@test 'uses the default secret path and forwards the command' {
  run_environment_exec gcloud project list

  [[ "$status" -eq 0 ]]
  default_secret_path="$TEST_ROOT/home/.config/shell-utils/environment/default.env"
  mapfile -d '' sops_args <"$TEST_ROOT/mock-args/sops.args"
  [[ "${sops_args[0]}" == 'exec-env' ]]
  [[ "${sops_args[1]}" == "$default_secret_path" ]]
  [[ "${sops_args[2]}" == 'gcloud project list' ]]
}

@test 'uses an explicit secret path with -f' {
  secret_file="$TEST_ROOT/custom.env"

  run_environment_exec -f "$secret_file" gcloud secrets list

  [[ "$status" -eq 0 ]]
  mapfile -d '' sops_args <"$TEST_ROOT/mock-args/sops.args"
  [[ "${sops_args[0]}" == 'exec-env' ]]
  [[ "${sops_args[1]}" == "$secret_file" ]]
  [[ "${sops_args[2]}" == 'gcloud secrets list' ]]
}

@test 'uses an explicit secret path with --file' {
  secret_file="$TEST_ROOT/long-option.env"

  run_environment_exec --file "$secret_file" gcloud secrets list

  [[ "$status" -eq 0 ]]
  mapfile -d '' sops_args <"$TEST_ROOT/mock-args/sops.args"
  [[ "${sops_args[1]}" == "$secret_file" ]]
}

@test 'fails when the command is missing' {
  run_environment_exec

  [[ "$status" -eq 1 ]]
}

@test 'propagates a sops failure' {
  printf '7\n' >"$TEST_ROOT/mock-status/sops"

  run_environment_exec gcloud project list

  [[ "$status" -eq 7 ]]
}
