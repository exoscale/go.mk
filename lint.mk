## staticcheck
#  REF: https://staticcheck.dev/

STATICCHECK_LINT_VERSION ?= latest
STATICCHECK_LINT_EXTRA_ARGS ?=

STATICCHECK_LINT ?= $(shell which staticcheck)

.PHONY: install-staticcheck installstaticchecklint
installstaticchecklint: install-staticcheck
install-staticcheck:
	'$(GO)' install honnef.co/go/tools/cmd/staticcheck@$(STATICCHECK_LINT_VERSION)

.PHONY: lint
lint: install-staticcheck
	'$(STATICCHECK_LINT)' \
	  $(STATICCHECK_LINT_EXTRA_ARGS) \
	  ./...
