## Release (publish) artifacts

RELEASE_DIR := $(CURDIR)/release
RELEASE_NOTES := $(RELEASE_DIR)/notes.md

# GoReleaser
# REF: https://github.com/goreleaser/goreleaser/

GORELEASER_VERSION ?= v1.18.2
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

.PHONY: release-precheck
release-precheck:
ifneq ($(shell umask), 0022)
	$(error Please set umask 0022 before performing a release)
endif
ifeq ($(VERSION), dev)
	$(warning Releasing the 'dev' VERSION is forbidden; generating a local snapshot instead)
endif
ifndef VERSION
	$(error Undefined variable VERSION)
endif
	@echo 'Release preliminary checks succeeded'

.PHONY: release-notes
release-notes $(RELEASE_NOTES): $(RELEASE_DIR)
ifndef PROJECT_URL
	$(error Undefined variable PROJECT_URL)
endif
	echo 'See the [CHANGELOG]($(PROJECT_URL)/blob/v$(VERSION)/CHANGELOG.md) for details.' > '$(RELEASE_NOTES)'

.PHONY: git-tag
git-tag:
ifdef DRYRUN
	@echo 'DRY-RUN: '"'"'$(INCLUDE_PATH)/git-tag.sh'"'"''
else
	'$(INCLUDE_PATH)/git-tag.sh'
endif

# The `git add --update vendor/` line works around https://groups.google.com/g/golang-nuts/c/yA94qG1xcsc
# If there are only CRLF and LF line ending changes git will consider the working tree clean after this.
# If there are actual changes in the vendored go modules they will be added to the staging area
# and thus goreleaser will fail as intended in this case.
.PHONY: release-default
release-default: release-precheck release-notes
	if [ -d "vendor" ]; then git add --update vendor/; fi
	'$(GORELEASER)' release $(GORELEASER_OPTS)

# Clean

.PHONY: clean
clean::
	rm -rf '$(CURDIR)/dist'
	rm -rf '$(RELEASE_DIR)'
