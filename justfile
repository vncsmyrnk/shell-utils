default:
  just --list

install-nix:
  @nix profile add .#

build-nix:
  @nix build .#

build:
  @rm -rf dist
  @mkdir dist
  CGO_ENABLED=0 go build \
    -ldflags="-s -w -X 'shellutils/internal.BaseDefaultScriptsPath=/usr/share/shell-utils/scripts'" \
    -trimpath \
    -o ./dist/util \
    ./cmd/runner/main.go
  CGO_ENABLED=0 go build \
    -ldflags="-s -w" \
    -trimpath \
    -o ./dist/config \
    ./cmd/config/main.go
  CGO_ENABLED=0 go build \
    -ldflags="-s -w -X 'shellutils/internal.BaseDefaultScriptsPath=/usr/share/shell-utils/scripts'" \
    -trimpath \
    -o ./dist/util-complete \
    ./cmd/completion/main.go

run *args:
  go build -o ./extra/config ./cmd/config/main.go
  @go run ./cmd/runner/main.go {{args}}

run-config *args:
  @go run ./cmd/config/main.go {{args}}

shellcheck *flags:
  @shellcheck {{flags}} $(rg "^#.*(bash|\/sh).*" extra -l)
