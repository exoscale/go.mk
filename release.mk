## Release (publish) artifacts

RELEASE_DIR := $(CURDIR)/release
RELEASE_NOTES := $(RELEASE_DIR)/notes.md

# GoReleaser
# REF: https://github.com/goreleaser/goreleaser/

GORELEASER_VERSION ?= v2.10.2
GORELEASER_OPTS ?= \
	--clean \
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
	'$(GO)' install github.com/goreleaser/goreleaser/v2@$(GORELEASER_VERSION)

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

CHANGELOG_FILENAME=CHANGELOG.md

.PHONY: prepare-release
prepare-release:
	@if [ -z "$(NEW_VERSION)" ]; then \
		echo "Error: NEW_VERSION is not set. Usage: make $@ NEW_VERSION=vX.Y.Z"; \
		exit 1; \
	fi
	@rm $(CHANGELOG_FILENAME)
	@git add $(CHANGELOG_FILENAME)
	@git commit -m "Prepare release"
	@git tag $(NEW_VERSION)
	$(MAKE) $(CHANGELOG_FILENAME)
	@git tag -d $(NEW_VERSION)
	@git add $(CHANGELOG_FILENAME)
	@git commit --amend -m  "Prepare release"
	@git tag $(NEW_VERSION)

TAGS := $(shell git tag | sort --version-sort --reverse)
INITIAL_COMMIT := $(shell git rev-list --max-parents=0 HEAD))

$(TAGS):
	./go.mk/scripts/generate-release-notes-for-tag.sh $@ >> $(CHANGELOG_FILENAME)

.PHONY: new-changelog
new-changelog:
	@printf "# Changelog\n\n" > $(CHANGELOG_FILENAME)

# creates a new changelog and generates the content for each git tag
.PHONY: $(CHANGELOG_FILENAME)
$(CHANGELOG_FILENAME): new-changelog $(TAGS)
