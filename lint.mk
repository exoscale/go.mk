## GoLang CI Linter
#  REF: https://github.com/golangci/golangci-lint/

GOLANGCI_LINT_VERSION ?= v1.51.2
GOLANGCI_LINT_TIMEOUT ?= 5m
GOLANGCI_LINT_CONFIG ?= go.mk/.golangci.yml
GOLANGCI_LINT_EXTRA_ARGS ?=

GOLANGCI_LINT ?= $(shell which golangci-lint)


## Targets

# Dependencies

.PHONY: install-golangci-lint installgolangcilint
installgolangcilint: install-golangci-lint
install-golangci-lint:
	'$(GO)' install github.com/golangci/golangci-lint/cmd/golangci-lint@$(GOLANGCI_LINT_VERSION)

# Lint

.PHONY: lint
lint: install-golangci-lint
	'$(GOLANGCI_LINT)' run \
	  --timeout $(GOLANGCI_LINT_TIMEOUT) \
    --config $(GOLANGCI_LINT_CONFIG) \
	  $(GOLANGCI_LINT_EXTRA_ARGS) \
	  ./...
