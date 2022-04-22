## Release (publish) artifacts

RELEASE_DIR := $(CURDIR)/release
RELEASE_NOTES := $(RELEASE_DIR)/notes.md

# GoReleaser
# REF: https://github.com/goreleaser/goreleaser/

GORELEASER_VERSION ?= v1.7.0
GORELEASER_OPTS ?= \
	--rm-dist \
	--release-notes '$(RELEASE_NOTES)'
ifneq ($(DRYRUN),)
GORELEASER_OPTS += --snapshot
else ifeq ($(VERSION), dev)
GORELEASER_OPTS += --snapshot
endif

GORELEASER ?= $(shell which goreleaser)


## Targets

# Dependencies

.PHONY: install-goreleaser installgoreleaser
installgoreleaser: install-goreleaser
install-goreleaser:
	echo Installing/updating 'goreleaser' executable
	'$(GO)' install github.com/goreleaser/goreleaser@$(GORELEASER_VERSION)

# Release

$(RELEASE_DIR):
	mkdir -p '$(RELEASE_DIR)'

.PHONY: release-notes
release-notes $(RELEASE_NOTES): $(RELEASE_DIR)
	echo 'See the [CHANGELOG]($(PROJECT_URL)/blob/v$(VERSION)/CHANGELOG.md) for details.' > '$(RELEASE_NOTES)'

.PHONY: git-tag
git-tag:
ifdef DRYRUN
	@echo 'DRY-RUN: '"'"'$(INCLUDE_PATH)/git-tag.sh'"'"''
else
	'$(INCLUDE_PATH)/git-tag.sh'
endif

.PHONY: release-default
release-default: release-notes
ifeq ($(VERSION), dev)
	$(warning Releasing the 'dev' VERSION is forbidden; generating a local snapshot instead)
endif
ifndef VERSION
	$(error Undefined variable VERSION)
else ifndef PROJECT_URL
	$(error Undefined variable PROJECT_URL)
else
	API_VERSION='$(API_VERSION)' '$(GORELEASER)' release $(GORELEASER_OPTS)
endif

# Clean

.PHONY: clean
clean::
	rm -rf '$(CURDIR)/dist'
	rm -rf '$(RELEASE_DIR)'
