default:
  just --list

install:
  nix profile add .#

build:
  @nix build .#

run *args:
  @go run ./cmd/runner/main.go {{args}}

shellcheck:
  shellcheck -s sh bin/** defaults/*/**.sh extra/*/**.sh
