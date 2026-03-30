default:
  just --list

install:
  nix profile add .#

build:
  @nix build .#

run *args:
  go build -o ./extra/config ./cmd/config/main.go
  @go run ./cmd/runner/main.go {{args}}

run-config *args:
  @go run ./cmd/config/main.go {{args}}

shellcheck:
  shellcheck -s sh bin/** defaults/*/**.sh extra/*/**.sh
