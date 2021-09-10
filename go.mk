GO ?=				$(shell which go)

GOIMPORTS ?= 		$(shell which goimports)

GO_PKGS ?= 			$(shell $(GO) list ./...)

GO_LD_FLAGS :=		-ldflags "-X main.commit=$(GIT_REVISION)              \
							  -X main.branch=$(GIT_BRANCH)                \
							  -X main.buildDate=$(shell date -u +%FT%T%z) \
							  -X main.version=$(VERSION)				  \
							  $(GO_LD_FLAGS)"

GO_TEST_PKGS ?= 	$(shell test -f go.mod && $(GO) list -f \
						'{{ if or .TestGoFiles .XTestGoFiles }}{{ .ImportPath }}{{ end }}' \
						$(GO_PKGS))

GO_TEST_TIMEOUT ?= 	15s

GO_TAGS ?=

GO_BIN_OUTPUT_DIR	?= $(CURDIR)/bin
GO_BIN_OUTPUT_NAME	?=

GOLANGCI_VERSION	?= v1.42.1
GOLANGCI_TIMEOUT	?= 5m
GOLANGCI_EXTRA_ARGS	?=

GO_MAIN_PKG_PATH ?= .

# ---

export GO111MODULE=on

# ---

.PHONY: vet
vet: ## Runs `go vet`
	$(GO) vet ./...


.PHONY: lint
lint: installgolangcilint ## Lints Go code
	golangci-lint run --modules-download-mode=vendor --timeout $(GOLANGCI_TIMEOUT) $(GOLANGCI_EXTRA_ARGS) ./...


.PHONY: test test-verbose
test: 				                ## Runs Go tests in silent mode
test-verbose: GO_TEST_EXTRA_ARGS=-v ## Runs Go tests in verbose mode
test test-verbose:
	$(GO) test                      \
		-race                       \
		-mod vendor                 \
		-timeout $(GO_TEST_TIMEOUT) \
		$(GO_TEST_EXTRA_ARGS)       \
		$(GO_TEST_PKGS)


.PHONY: build build-verbose
build-verbose: GO_BUILD_EXTRA_ARGS=-v  						## Builds a Go binary in verbose mode
build:            											## Builds a Go binary in silent mode
build build-verbose:
	        mkdir -p $(GO_BIN_OUTPUT_DIR)
	        $(GO) build                                   \
		$(GO_BUILD_EXTRA_ARGS)                        \
		$(GO_LD_FLAGS)                                \
		$(GO_TAGS)                                    \
		-mod vendor                                   \
		-o $(GO_BIN_OUTPUT_DIR)/$(GO_BIN_OUTPUT_NAME) \
		$(GO_MAIN_PKG_PATH)


.PHONY: clean
clean::	## Removes compiled Go binaries
	rm -rf $(GO_BIN_OUTPUT_DIR)


.PHONY: clean-gocache
clean-gocache: ## Removes Go's module and test cache
	$(GO) clean -cache -testcache


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


.PHONY: vendor
vendor:
	go mod vendor


.PHONY: fmt
.ONESHELL:
fmt:  ## Formats Go source files
	@for d in $(shell go list -f '{{.Dir}}' ./...);do
		$(GOIMPORTS) -w $$d/*.go
	done

.PHONY: git-tag
git-tag: ## Creates a Git tag
	@$(INCLUDE_PATH)/git-tag.sh

# Allow go.mk targets to be overrididden in external Makefiles:
# https://newbedev.com/make-file-warning-overriding-commands-for-target
%: %-default
	@ true
