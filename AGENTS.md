# Repository Guidelines

## Scope

These guidelines apply to the entire `shell-utils` repository.

## Command routing

- Implement command routing and related CLI behavior in Go.
- Do not add command-routing logic to individual shell scripts.
- Update generated routing code through the existing `go generate ./...` workflow; do not edit generated files manually.
- When a command's flags or positional-argument contract changes, update
  `completions/schema.kdl` and regenerate the actual completion files with
  `make completions`; do not edit generated completion files manually.

## Go

- Follow Effective Go and idiomatic Go conventions.
- Keep package responsibilities clear and code testable.
- Use explicit, contextual error handling; do not silently discard errors.
- Format Go files with `gofmt`.
- Add focused tests for changed behavior and run `go test ./...` when Go code changes.

## Scripts

- Every script MUST detect required external commands, files, modules, and
  runtime dependencies before use, and report an actionable error when any are
  unavailable.
- Every script MUST handle errors explicitly, preserve failure status, and
  report contextual diagnostics; scripts MUST NOT silently suppress errors or
  present failed operations as successful.
- **Trigger:** a user-invoked command script is added or changed. **Action:**
  you MUST add or update its corresponding test under `tests/`.

## Bash scripts

- Prefer Bash for repository scripts and supporting shell glue.
- Apply the following requirements to new or modified Bash scripts; do not
  retrofit existing scripts solely to meet them.
- Every Bash script MUST include a concise description and document all
  accepted flags and positional inputs in its help block or equivalent
  user-facing documentation; explicitly state when no flags or inputs are
  accepted.
- Every executable script MUST begin with `#!/usr/bin/env bash`.
- Executable scripts must declare required environment-variable defaults safely
  under `nounset` and source dependencies, with ShellCheck source annotations,
  in their first logical section.
- Scripts that accept options must parse them before positional arguments, honor
  `--` as the end of options, and preserve all subsequent operands unchanged.
- Keep executable-script top level limited to setup and `main "$@"`. Put
  operational logic in focused functions; use `name()` syntax and `local` for
  function-scoped variables.
- When sibling command scripts share variables, store them in `_variables.sh`.
  Sourced `_variables.sh` and `_lib.sh` support modules must expose only
  declarations and functions; they do not require CLI argument parsing or
  `main`.
- Follow the [YSAP Bash Style Guide](https://style.ysap.sh/) as the canonical
  source for the following invariants and as the disambiguation reference for
  their wording.
- **[Aesthetics](https://style.ysap.sh/#aesthetics):** scripts MUST use tabs, stay within 80 columns, avoid
  semicolons except where control syntax requires them, use `name()` functions
  with local variables, put `then` and `do` on the same line as their control
  statement, use no more than one consecutive blank line, and preserve comments
  unless rewriting or updating them.
- **[Bashisms](https://style.ysap.sh/#bashisms):** scripts MUST use `[[ ... ]]` instead of `test` or `[ ... ]`,
  Bash-native sequences, `$(...)` command substitution, `((...))` arithmetic,
  parameter expansion instead of external commands for simple transformations,
  Bash-native file iteration instead of parsing `ls`, arrays for lists, and
  `read` where practical. Scripts MUST NOT assume a reliable executable
  directory path when the design does not require one.
- **[External commands](https://style.ysap.sh/#external-commands):** scripts SHOULD avoid GNU-specific options when
  portability matters and MUST NOT use `cat` when redirection or a command's
  file argument is sufficient.
- **[Style](https://style.ysap.sh/#style):** scripts MUST use double quotes for interpolated strings and single
  quotes otherwise; quote expansions that can undergo word splitting; use
  lowercase variable names except for constants and exported variables; use
  `/usr/bin/env bash`; check commands such as `cd` for failure; MUST NOT set
  `errexit` or use `eval`.
- **[Common mistakes](https://style.ysap.sh/#common-mistakes):** scripts MUST quote expansions rather than relying on
  braces for word-splitting safety, and MUST use `while IFS= read -r` for
  newline-delimited streams instead of using `for` over split command output.
- **Trigger:** a command's primary objective is displaying data. **Action:**
  its tests MUST assert the intended standard output; tests for other commands
  MUST assert exit status, side effects, and diagnostics without making
  progress or status text an exact output contract.
- Keep scripts ShellCheck-compatible; use the repository's `.shellcheckrc` configuration.

## Bats tests

- **Trigger:** a new or modified Bats test is added or changed. **Action:** you
  MUST apply this pattern to the change without retrofitting existing tests
  solely for compliance.
- **Trigger:** a Bats test file is created or modified. **Action:** you MUST
  keep these sections in order, omitting only sections that do not apply:
  the Bats shebang and shared-helper load; `setup()` containing test-root and
  runtime variables, fixtures, shared mock setup, and one uppercase
  `<COMMAND>_ENV` array; one local `run_<command>()`; then arrange, act, and
  assert test cases.
- **Trigger:** a Bats test case is added or modified. **Action:** you MUST
  separate arrange, act, and assert phases with blank lines and assert exit
  status first.
- **Trigger:** an environment array is added or modified in a Bats test.
  **Action:** you MUST order its entries as repository and script paths,
  command configuration, mock capture and output paths, then `PATH`.
- **Trigger:** a local Bats runner is defined. **Action:** it MUST invoke
  `run env "${<COMMAND>_ENV[@]}" ...` and forward `"$@"` unchanged.
- **Trigger:** a Bats test defines fixtures, environment arrays, runners, or
  assertions. **Action:** you MUST keep them local to the test file.
- **Trigger:** a Bats test creates fixture or mock state. **Action:** you MUST
  keep that state under `BATS_TEST_TMPDIR`.
- **Trigger:** a new or modified Bats test adds or changes an external-command
  mock. **Action:** you MUST put one reusable executable definition for that
  command in `tests/test_helper.bash`. Command- or suite-specific definitions
  are permitted; a generic mock-factory abstraction is unnecessary.
- **Trigger:** a shared executable mock is defined. **Action:** it MUST be
  deterministic, preserve argument boundaries, emit only configured output,
  support configured failure, and diagnose missing required configuration.
  When exact argument vectors matter, capture them as NUL-delimited data.
- **Trigger:** a new or modified Bats test needs a command mocked in another
  file. **Action:** you MUST move that definition to
  `tests/test_helper.bash` and migrate the other duplicates to that single
  source of truth.
- **Trigger:** Bats tests or `tests/test_helper.bash` change. **Action:** you
  MUST run `make check` and `make lint`.

## Validation

Run the checks relevant to the files changed:

```bash
make check
make lint
```

`make check` runs ShellCheck and the Bats suite. Use `make test` for a focused
Bats-only run.

- **Trigger:** a change affects the Nix flake, build, packaging, or build inputs. **Action:** you MUST run `make buildflake` and confirm it succeeds before considering the change complete.

For Go changes, also run:

```bash
gofmt -w path/to/changed.go
go test ./...
```

Do not overwrite or revert unrelated worktree changes.
