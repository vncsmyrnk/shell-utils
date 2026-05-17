OUTPUT = .out

SRCDIR = .

GO_SRC = $(shell find . -type f -name '*.go')
COMPLETION_SRC = $(SRCDIR)/completions
MAN1_SRC = $(wildcard $(SRCDIR)/man/*)
SCRIPTS_SRC = $(shell find $(SRCDIR)/extra -type f)

SCRIPTS = $(OUTPUT)/scripts
SCRIPTS_STAMP = $(OUTPUT)/.scripts.stamp
PRIVKEY = $(OUTPUT)/signing.key
PUBKEY = $(OUTPUT)/signing.pub
MANIFEST = $(OUTPUT)/manifest.json
RUNNER = $(OUTPUT)/util
CONFIG = $(OUTPUT)/config
PACKAGES = $(OUTPUT)/packages
FETCH = $(OUTPUT)/util-fetch
COMPLETION = $(OUTPUT)/util-complete

PREFIX ?= /usr
DESTDIR ?=

DATAROOTDIR = $(PREFIX)/share
DATADIR = $(DATAROOTDIR)
BINDIR = $(PREFIX)/bin
MANDIR = $(DATAROOTDIR)/man
MANDIR1 = $(MANDIR)/man1
ZSHDIR = $(DATAROOTDIR)/zsh

INSTALL ?= install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

GO ?= go
GO_FLAGS = -trimpath
GO_ENV ?= CGO_ENABLED=0
GO_LDFLAGS ?= -s -w

GO_LDFLAGS_BASE_PATH = -X 'shellutils/internal.BaseDefaultPath=$(PREFIX)/share/shell-utils' \
											 -X 'shellutils/internal.BaseDefaultScriptsPath=$(PREFIX)/share/shell-utils/scripts'

GO_LDFLAGS_DEFAULT_SCRIPTS_KEY = -X 'shellutils/internal/security.GlobalPublicKeyHex=$$(cat $(PUBKEY))'

all: $(RUNNER) $(SCRIPTS) $(FETCH) $(COMPLETION)

.PHONY: clean
clean:
	@rm -rf $(OUTPUT)

.PHONY: install
install: all
	$(INSTALL) -d $(DESTDIR)$(DATADIR)/shell-utils/scripts
	$(INSTALL) -d $(DESTDIR)$(MANDIR1)
	$(INSTALL_DATA) $(MANIFEST) $(DESTDIR)$(DATADIR)/shell-utils
	$(INSTALL) -d $(DESTDIR)$(ZSHDIR)/site-functions
	$(INSTALL_DATA) $(COMPLETION_SRC)/zsh/_util $(DESTDIR)$(ZSHDIR)/site-functions/_util
	$(INSTALL_DATA) $(COMPLETION_SRC)/zsh/*.completions.zsh $(DESTDIR)$(ZSHDIR)/site-functions/
	$(INSTALL_DATA) $(MAN1_SRC) $(DESTDIR)$(MANDIR1)
	$(INSTALL) -d $(DESTDIR)$(BINDIR)
	$(INSTALL_PROGRAM) $(RUNNER) $(DESTDIR)$(BINDIR)/util
	$(INSTALL_PROGRAM) $(COMPLETION) $(DESTDIR)$(BINDIR)/util-complete
	$(INSTALL_PROGRAM) $(FETCH) $(DESTDIR)$(BINDIR)/util-fetch
	cp -r $(SCRIPTS)/. $(DESTDIR)$(DATADIR)/shell-utils/scripts/
	find $(DESTDIR)$(DATADIR)/shell-utils/scripts/ -type d -print0 | xargs -0 chmod 755
	find $(DESTDIR)$(DATADIR)/shell-utils/scripts/ -type f -print0 | xargs -0 chmod 644

.PHONY: uninstall
uninstall:
	rm -rf $(DESTDIR)$(DATADIR)/shell-util
	rm -f $(DESTDIR)$(MANDIR1)/util.1
	rm -f $(DESTDIR)$(BINDIR)/util $(DESTDIR)$(BINDIR)/util-complete $(DESTDIR)$(BINDIR)/util-fetch
	rm -f $(DESTDIR)$(ZSHDIR)/site-functions/_util
	rm -f $(DESTDIR)$(ZSHDIR)/site-functions/_config.completions.zsh

.PHONY: check
check:
	shellcheck $$(rg "^#.*(bash|\/sh).*" $(SCRIPTS_SRC) -l)
	GOLANGCI_LINT_CACHE=$$(mktemp -d) golangci-lint run $(SRCDIR)/...

.PHONY: installcheck
installcheck:
	@echo "Verifying installation in $(DESTDIR)$(PREFIX)..."

	@test -x $(DESTDIR)$(BINDIR)/util || (echo "Error: util binary not found or not executable" && exit 1)
	@test -x $(DESTDIR)$(BINDIR)/util-complete || (echo "Error: util-complete binary not found or not executable" && exit 1)
	@test -x $(DESTDIR)$(BINDIR)/util-fetch || (echo "Error: util-fetch binary not found or not executable" && exit 1)

	@test -d $(DESTDIR)$(DATADIR)/shell-utils/scripts || (echo "Error: Script directory missing" && exit 1)

	$(DESTDIR)$(BINDIR)/util install-check > /dev/null
	$(DESTDIR)$(BINDIR)/util-fetch $(DESTDIR)$(DATADIR)/shell-utils/scripts/install-check.sh > /dev/null
	$(DESTDIR)$(BINDIR)/util-complete install-check > /dev/null

	@echo "Installation verification passed successfully!"

$(SCRIPTS): $(SCRIPTS_SRC) $(CONFIG) $(PACKAGES)
	@mkdir -p $@
	cp --parents -r $? $@
	find $(SCRIPTS) -mindepth 2 -maxdepth 2 -exec mv {} $(SCRIPTS) \;
	find $(SCRIPTS) -type d -empty -print0 | xargs -0 rmdir

$(PRIVKEY) $(PUBKEY)&:
	$(GO) run ./cmd/keygen/main.go $(OUTPUT)

$(MANIFEST): $(PRIVKEY) $(SCRIPTS) $(wildcard ./cmd/manifestgen/*.go)
	$(GO) run ./cmd/manifestgen/main.go $(SCRIPTS) $$(cat $(PRIVKEY)) $(OUTPUT)

$(RUNNER): $(MANIFEST) $(GO_SRC)
	$(GO_ENV) $(GO) build \
		$(GO_FLAGS) \
		-ldflags="$(GO_LDFLAGS) $(GO_LDFLAGS_BASE_PATH) $(GO_LDFLAGS_DEFAULT_SCRIPTS_KEY)" \
		-o $@ ./cmd/runner/main.go

$(CONFIG): $(GO_SRC)
	$(GO_ENV) $(GO) build \
		$(GO_FLAGS) \
		-ldflags="$(GO_LDFLAGS)" \
		-o $@ ./cmd/config/main.go

$(PACKAGES): $(GO_SRC)
	$(GO_ENV) $(GO) build \
		$(GO_FLAGS) \
		-ldflags="$(GO_LDFLAGS)" \
		-o $@ ./cmd/packages/main.go

$(FETCH): $(MANIFEST) $(GO_SRC)
	$(GO_ENV) $(GO) build \
		$(GO_FLAGS) \
		-ldflags="$(GO_LDFLAGS) $(GO_LDFLAGS_BASE_PATH) $(GO_LDFLAGS_DEFAULT_SCRIPTS_KEY)" \
		-o $@ ./cmd/fetch/main.go

$(COMPLETION): $(GO_SRC)
	$(GO_ENV) $(GO) build \
		$(GO_FLAGS) \
		-ldflags="$(GO_LDFLAGS) $(GO_LDFLAGS_BASE_PATH)" \
		-o $@ ./cmd/completion/main.go
