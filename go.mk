## Project
GO_MAIN_PKG_PATH ?= .
GO_PKGS ?= $(shell $(GO) list ./...)
GO_TAGS ?=

# Output
GO_BIN_OUTPUT_DIR ?= $(CURDIR)/bin
GO_BIN_OUTPUT_NAME ?=


## GoLang
GO ?= $(shell which go)
ifeq ($(GO),)
  $(error Failed to locate 'go' binary)
endif
GO_LD_FLAGS := \
	-ldflags "-X main.commit=$(GIT_REVISION) \
	-X main.branch=$(GIT_BRANCH) \
	-X main.buildDate=$(shell date -u +%FT%T%z) \
	-X main.version=$(VERSION) \
	$(GO_LD_FLAGS)"

# Tests
GO_TEST_PKGS ?= \
	$(shell test -f go.mod && '$(GO)' list -f \
	  '{{ if or .TestGoFiles .XTestGoFiles }}{{ .ImportPath }}{{ end }}' \
	  $(GO_PKGS) \
	)
GO_TEST_TIMEOUT ?= 15s

# Modules
export GO111MODULE=on

# Dependencies
include $(INCLUDE_PATH)/fmt.mk
include $(INCLUDE_PATH)/lint.mk
include $(INCLUDE_PATH)/coverage.mk


## Targets

# Dependencies

.PHONY: vendor
vendor:
	'$(GO)' mod vendor

# Source

.PHONY: vet
vet:
	'$(GO)' vet ./...

# Tests

.PHONY: test test-verbose
test:  ## Runs Go tests in silent mode
test-verbose: GO_TEST_EXTRA_ARGS=-v  ## Runs Go tests in verbose mode
test test-verbose:
	'$(GO)' test \
	  -race \
	  -timeout $(GO_TEST_TIMEOUT) \
	  $(GO_TEST_EXTRA_ARGS) \
	  $(GO_TEST_PKGS)

# Build

$(GO_BIN_OUTPUT_DIR):
	mkdir -p '$(GO_BIN_OUTPUT_DIR)'

.PHONY: build build-verbose
build:  ## Builds a Go binary in silent mode
build-verbose: GO_BUILD_EXTRA_ARGS=-v  ## Builds a Go binary in verbose mode
build build-verbose $(GO_BIN_OUTPUT_DIR)/$(GO_BIN_OUTPUT_NAME): $(GO_BIN_OUTPUT_DIR)
	'$(GO)' build \
	  $(GO_BUILD_EXTRA_ARGS) \
	  $(GO_LD_FLAGS) \
	  $(GO_TAGS) \
	  -o '$(GO_BIN_OUTPUT_DIR)/$(GO_BIN_OUTPUT_NAME)' \
	  '$(GO_MAIN_PKG_PATH)'

# Clean

.PHONY: clean
clean::
	rm -rf '$(GO_BIN_OUTPUT_DIR)'

.PHONY: clean-gocache
clean-gocache:
	'$(GO)' clean -cache -testcache
