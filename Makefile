OUTPUT = .out

SCRIPTS = $(OUTPUT)/scripts
SCRIPTS_STAMP = $(OUTPUT)/.scripts.stamp
KEYS = $(OUTPUT)/signing.key $(OUTPUT)/signing.pub
MANIFEST = $(OUTPUT)/manifest.json
RUNNER = $(OUTPUT)/util
CONFIG = $(OUTPUT)/config
PACKAGES = $(OUTPUT)/packages
FETCH = $(OUTPUT)/util-fetch
COMPLETION = $(OUTPUT)/util-complete
GO_SRC = $(shell find . -type f -name '*.go')

PREFIX ?= /usr
DESTDIR ?=

INSTALL_SHARE=$(DESTDIR)$(PREFIX)/share/shell-utils
INSTALL_BIN=$(DESTDIR)$(PREFIX)/bin
INSTALL_MAN=$(DESTDIR)$(PREFIX)/share/man
INSTALL_ZSH=$(DESTDIR)$(PREFIX)/share/zsh

GO_LDFLAGS = -s -w \
						 -X 'shellutils/internal.BaseDefaultPath=$(PREFIX)/share/shell-utils' \
						 -X 'shellutils/internal.BaseDefaultScriptsPath=$(PREFIX)/share/shell-utils/scripts'

all: $(RUNNER) $(SCRIPTS_STAMP) $(FETCH) $(COMPLETION)

.PHONY: clean
clean:
	@rm -rf $(OUTPUT)

.PHONY: install
install: all
	install -d -m755 "$(INSTALL_SHARE)/scripts"
	install -d -m755 "$(INSTALL_MAN)/man1/"
	install -Dm755 $(RUNNER) "$(INSTALL_BIN)/util"
	install -Dm755 $(COMPLETION) $(INSTALL_BIN)/util-complete
	install -Dm755 $(FETCH) $(INSTALL_BIN)/util-fetch
	install -Dm755 $(MANIFEST) $(INSTALL_SHARE)/
	install -Dm644 ./completions/zsh/_util $(INSTALL_ZSH)/site-functions/_util
	install -Dm644 ./completions/zsh/*.completions.zsh $(INSTALL_ZSH)/site-functions/
	install -m644 ./man/* $(INSTALL_MAN)/man1/
	cp -r $(SCRIPTS)/* $(INSTALL_SHARE)/scripts/
	find $(INSTALL_SHARE)/scripts -type d -print0 | xargs -0 chmod 755
	find $(INSTALL_SHARE)/scripts -type f -print0 | xargs -0 chmod 644

.PHONY: uninstall
uninstall:
	rm -rf $(INSTALL_SHARE)
	rm -f $(INSTALL_MAN)/man1/util.1
	rm -f $(INSTALL_BIN)/util $(INSTALL_BIN)/util-complete $(INSTALL_BIN)/util-fetch
	rm -f $(INSTALL_ZSH)/site-functions/_util
	rm -f $(INSTALL_ZSH)/site-functions/_config.completions.zsh

.PHONY: check
check:
	shellcheck $$(rg "^#.*(bash|\/sh).*" extra -l)
	GOLANGCI_LINT_CACHE=$$(mktemp -d) golangci-lint run ./...

.PHONY: installcheck
installcheck:
	@echo "Verifying installation in $(DESTDIR)$(PREFIX)..."

	@test -x "$(INSTALL_BIN)/util" || (echo "Error: util binary not found or not executable" && exit 1)
	@test -x "$(INSTALL_BIN)/util-complete" || (echo "Error: util-complete binary not found or not executable" && exit 1)
	@test -x "$(INSTALL_BIN)/util-fetch" || (echo "Error: util-fetch binary not found or not executable" && exit 1)

	@test -d "$(INSTALL_SHARE)/scripts" || (echo "Error: Script directory missing" && exit 1)

	"$(INSTALL_BIN)/util" install-check > /dev/null
	"$(INSTALL_BIN)/util-complete" install-check > /dev/null
	"$(INSTALL_BIN)/util-fetch" "$(INSTALL_SHARE)/scripts/install-check.sh" > /dev/null

	@echo "Installation verification passed successfully!"

$(SCRIPTS_STAMP): $(CONFIG) $(PACKAGES) $(wildcard ./extra/*)
	@mkdir -p $(SCRIPTS)
	cp -r ./extra/* $(SCRIPTS)/
	cp $(CONFIG) $(SCRIPTS)/
	cp $(PACKAGES) $(SCRIPTS)/
	@touch $@

$(KEYS)&:
	go run ./cmd/keygen/main.go $(OUTPUT)

$(MANIFEST): $(KEYS) $(SCRIPTS_STAMP) $(wildcard ./cmd/manifestgen/*.go)
	go run ./cmd/manifestgen/main.go $(SCRIPTS) $$(cat $(OUTPUT)/signing.key) $(OUTPUT)

$(RUNNER): $(MANIFEST) $(GO_SRC)
	CGO_ENABLED=0 go build \
		-trimpath \
		-ldflags="$(GO_LDFLAGS) \
			-X 'shellutils/internal/security.GlobalPublicKeyHex=$$(cat $(OUTPUT)/signing.pub)'" \
		-o $@ ./cmd/runner/main.go

$(CONFIG): $(GO_SRC)
	CGO_ENABLED=0 go build \
		-trimpath \
		-ldflags="$(GO_LDFLAGS)" \
		-o $@ ./cmd/config/main.go

$(PACKAGES): $(GO_SRC)
	CGO_ENABLED=0 go build \
		-trimpath \
		-ldflags="$(GO_LDFLAGS)" \
		-o $@ ./cmd/packages/main.go


$(FETCH): $(MANIFEST) $(GO_SRC)
	CGO_ENABLED=0 go build \
		-trimpath \
		-ldflags="$(GO_LDFLAGS) \
			-X 'shellutils/internal/security.GlobalPublicKeyHex=$$(cat $(OUTPUT)/signing.pub)'" \
		-o $@ ./cmd/fetch/main.go

$(COMPLETION): $(GO_SRC)
	CGO_ENABLED=0 go build \
		-trimpath \
		-ldflags="$(GO_LDFLAGS) \
			-X 'shellutils/internal/security.GlobalPublicKeyHex=$$(cat $(OUTPUT)/signing.pub)'" \
		-o $@ ./cmd/completion/main.go
