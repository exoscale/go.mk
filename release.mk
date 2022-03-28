## GoReleaser
#  REF: https://github.com/goreleaser/goreleaser/

GORELEASER_VERSION ?= v1.7.0
GORELEASER_OPTS ?= \
	--rm-dist \
	--release-notes <(echo "See the [CHANGELOG]($(PROJECT_URL)/blob/v$(VERSION)/CHANGELOG.md) for details.")

GORELEASER ?= $(shell which goreleaser)


## Targets

# Dependencies

.PHONY: install-goreleaser installgoreleaser
installgoreleaser: install-goreleaser
install-goreleaser:
	echo Installing/updating 'goreleaser' executable
	'$(GO)' install github.com/goreleaser/goreleaser@$(GORELEASER_VERSION)

# Release

.PHONY: git-tag
git-tag:
ifdef DRYRUN
	@echo 'DRY-RUN: '"'"'$(INCLUDE_PATH)/git-tag.sh'"'"''
else
	'$(INCLUDE_PATH)/git-tag.sh'
endif

.PHONY: release-default
release-default:
ifndef VERSION
	$(error Undefined variable VERSION)
else ifeq ($(VERSION), dev)
	$(error Releasing the 'dev' VERSION is forbidden)
else ifndef PROJECT_URL
	$(error Undefined variable PROJECT_URL)
else ifdef DRYRUN
	@echo 'DRY-RUN: '"'"'$(GORELEASER)'"'"' release $(GORELEASER_OPTS)'
else
	'$(GORELEASER)' release $(GORELEASER_OPTS)
endif
