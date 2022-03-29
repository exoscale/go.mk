## Go Imports (formatter)
#  REF: https://pkg.go.dev/golang.org/x/tools/cmd/goimports

GOIMPORTS_VERSION ?= v0.1.10

GOIMPORTS ?= $(shell which goimports)


## Targets

# Dependencies

.PHONY: install-goimports
install-goimports:
	'$(GO)' install golang.org/x/tools/cmd/goimports@$(GOIMPORTS_VERSION)

# Format

.PHONY: fmt
fmt: install-goimports
	IFS=$$'\n'; for dir in $(shell go list -f '{{.Dir}}' ./...); do \
	  '$(GOIMPORTS)' -w "$${dir}"/*.go; \
	done
