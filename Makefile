SRCDIR = .

OUTPUT = $(SRCDIR)/build

GO_SRC = $(shell find $(SRCDIR) -type f -name '*.go')
MAN1_SRC = $(wildcard $(SRCDIR)/man/*)
SCRIPTS_SRC = $(shell find $(SRCDIR)/scripts -type f)
COMPLETION_SRC = $(SRCDIR)/completions

UTIL = $(OUTPUT)/util

VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || cat VERSION 2>/dev/null || echo "unknown")

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
GO_LDFLAGS ?= -s -w -X 'shellutils/internal.DataPath=$(PREFIX)/share/shell-utils' \
							-X 'shellutils/internal.Version=$(VERSION)'

all: $(UTIL)

.PHONY: clean
clean:
	@rm -rf $(OUTPUT)

.PHONY: install
install: all
	$(INSTALL) -d $(DESTDIR)$(DATADIR)/shell-utils/scripts
	$(INSTALL) -d $(DESTDIR)$(ZSHDIR)/site-functions
	$(INSTALL) -d $(DESTDIR)$(BINDIR)
	$(INSTALL_PROGRAM) $(UTIL) $(DESTDIR)$(BINDIR)
	$(INSTALL_DATA) $(COMPLETION_SRC)/zsh/_util $(DESTDIR)$(ZSHDIR)/site-functions/_util
	cp -r $(SRCDIR)/scripts $(DESTDIR)$(DATADIR)/shell-utils/
	find $(DESTDIR)$(DATADIR)/shell-utils/scripts/ -type d -print0 | xargs -0 chmod 755
	find $(DESTDIR)$(DATADIR)/shell-utils/scripts/ -type f -print0 | xargs -0 chmod 755
	find $(DESTDIR)$(DATADIR)/shell-utils/scripts/ -type f -name help -print0 | xargs -0 chmod 644

.PHONY: install-local
install-local: all
	$(MAKE) PREFIX=$(shell realpath $(SRCDIR)/dist) install

.PHONY: uninstall
uninstall:
	rm -rf $(DESTDIR)$(DATADIR)/shell-util
	rm -f $(DESTDIR)$(BINDIR)/util
	rm -f $(DESTDIR)$(ZSHDIR)/site-functions/_util
	rm -f $(DESTDIR)$(ZSHDIR)/site-functions/_config.completions.zsh

.PHONY: uninstall-local
uninstall-local:
	rm -rf $(SRCDIR)/dist

.PHONY: check
check:
	shellcheck $$(rg "^#.*(bash|\/sh).*" $(SCRIPTS_SRC) -l)

.PHONY: lint
lint:
	GOLANGCI_LINT_CACHE=$$(mktemp -d) golangci-lint run $(SRCDIR)/...

.PHONY: installcheck
installcheck:
	@echo "Verifying installation in $(DESTDIR)$(PREFIX)..."

	@test -x $(DESTDIR)$(BINDIR)/util || (echo "Error: util binary not found or not executable" && exit 1)
	@test -d $(DESTDIR)$(DATADIR)/shell-utils/scripts || (echo "Error: Script directory missing" && exit 1)

	$(DESTDIR)$(BINDIR)/util install-check > /dev/null

	@echo "Installation verification passed successfully!"

.PHONY: buildflake
buildflake:
	@nix build .# -L

.PHONY: completions
completions: $(SRCDIR)/completions/zsh/_util

$(SRCDIR)/completions/zsh/_util: $(SRCDIR)/completions.kdl
	cg --shell zsh $< > $(SRCDIR)/completions/zsh/_util

$(UTIL): $(GO_SRC)
	$(GO) generate ./...
	$(GO_ENV) $(GO) build \
		$(GO_FLAGS) \
		-ldflags="$(GO_LDFLAGS)" \
		-o $@ ./cmd/util/...
