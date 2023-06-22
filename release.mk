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

# execute release procedures that don't require docker
release-non-docker: release-precheck release-notes
	cat .goreleaser.main.yml .goreleaser.non-docker.yml > .goreleaser.yml
	'$(GORELEASER)' release $(GORELEASER_OPTS)

# execute release procedures inside a docker container
release-in-docker:
	docker run \
	    --env GITHUB_TOKEN=$(GITHUB_TOKEN) \
	    --volume=$(CURDIR):/src:ro \
	    --volume=src-snapshot:/snapshot \
	    --volume=build-cache:/root/.cache/go-build \
	    --volume=go-mod-cache:/root/go/pkg/mod \
	    registry.service.exoscale.net/exoscale/go.mk

# execute release procedures that require docker
release-docker: release-precheck release-notes
	cat .goreleaser.main.yml .goreleaser.docker.yml > .goreleaser.yml
	'$(GORELEASER)' release $(GORELEASER_OPTS)

.PHONY: release-default
release-default: release-in-docker release-docker

# Clean

.PHONY: clean
clean::
	rm -rf '$(CURDIR)/dist'
	rm -rf '$(RELEASE_DIR)'
