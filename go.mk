GO ?=				$(shell which go)

GOIMPORTS ?= 		$(shell which goimports)

GO_PKGS ?= 			$(shell $(GO) list ./...)

GO_LD_FLAGS ?=		-ldflags "-X main.commit=$(GIT_REVISION)              \
							  -X main.branch=$(GIT_BRANCH)                \
							  -X main.buildDate=$(shell date -u +%FT%T%z) \
							  -X main.version=$(VERSION)"

GO_TEST_PKGS ?= 	$(shell test -f go.mod && $(GO) list -f \
						'{{ if or .TestGoFiles .XTestGoFiles }}{{ .ImportPath }}{{ end }}' \
						$(GO_PKGS))

GO_VENDOR_DIR ?=	vendor

GO_TEST_TIMEOUT ?= 	15s

GO_TAGS ?=

GO_BIN_OUTPUT_DIR ?= $(CURDIR)/bin
GO_BIN_OUTPUT_NAME ?=

GOLANGCI_VERSION ?= v1.24.0
GOLANGCI_TIMEOUT ?= 5m

GO_MAIN_PKG_PATH ?= .

# ---

export GO111MODULE=on

# ---

.PHONY: vet
vet: ## Run go vet
	$(GO) vet ./...


.PHONY: lint
lint: installgolangcilint ## Lint go code
	golangci-lint run --modules-download-mode=$(GO_VENDOR_DIR) --timeout $(GOLANGCI_TIMEOUT) ./...


.PHONY: test test-verbose
test: 				                ## Run go tests in silent mode
test-verbose: GO_TEST_EXTRA_ARGS=-v ## Run go tests in verbose mode
test test-verbose:
	$(GO) test                      \
		-race                       \
		-mod $(GO_VENDOR_DIR)       \
		-timeout $(GO_TEST_TIMEOUT) \
		$(GO_TEST_EXTRA_ARGS)       \
		$(GO_TEST_PKGS)


.PHONY: build build-verbose
build-verbose: GO_BUILD_EXTRA_ARGS=-v  						## Builds a go binary in verbose mode
build:            											## Builds a go binary in silent mode
build build-verbose: $(GO_BIN_OUTPUT_DIR) createvendordir
	$(GO) build                                       \
		$(GO_BUILD_EXTRA_ARGS)                        \
		$(GO_LD_FLAGS)                                \
		$(GO_TAGS)                                    \
		-mod $(GO_VENDOR_DIR)                         \
		-o $(GO_BIN_OUTPUT_DIR)/$(GO_BIN_OUTPUT_NAME) \
		$(GO_MAIN_PKG_PATH)


.PHONY: clean
clean::	## Removes compiled go binaries
	rm -rf $(GO_BIN_OUTPUT_DIR)


.PHONY: $(GO_BIN_OUTPUT_DIR)
$(GO_BIN_OUTPUT_DIR):
	test -d $(GO_BIN_OUTPUT_DIR) || mkdir $(GO_BIN_OUTPUT_DIR)


.PHONY: installgolangcilint
.ONESHELL:
installgolangcilint: ## Installs golangcilint (https://golangci.com/)
	if [ ! -f $(shell go env GOPATH)/bin/golangci-lint ]; then
		curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | \
			sh -s -- -b $(shell go env GOPATH)/bin $(GOLANGCI_VERSION)
	fi


.PHONY: createvendordir
createvendordir:
	test -d $(GO_VENDOR_DIR) || mkdir $(GO_VENDOR_DIR)
	go mod $(GO_VENDOR_DIR)


.PHONY: fmt
.ONESHELL:
fmt:  ## Formats source files
	@for d in $(shell go list -f '{{.Dir}}' ./...);do
		$(GOIMPORTS) -w $$d/*.go
	done

.PHONY: git-tag
git-tag: ## Creates a git tag
	@$(INCLUDE_PATH)/git-tag.sh
