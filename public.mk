GORELEASER_VERSION  ?= v0.178.0
GORELEASER_OPTS     ?= --rm-dist --release-notes <(echo "See the [CHANGELOG]($(PROJECT_URL)/blob/v$(VERSION)/CHANGELOG.md) for details.")

.PHONY: installgoreleaser
.ONESHELL:
installgoreleaser: ## Installs GoReleaser (https://goreleaser.com/)
	if [ ! -f $(shell go env GOPATH)/bin/goreleaser ]; then
		curl -sfL https://install.goreleaser.com/github.com/goreleaser/goreleaser.sh | \
			sh -s -- -b $(shell go env GOPATH)/bin $(GORELEASER_VERSION)
	fi

.PHONY: release
.ONESHELL:
release-default: SHELL:=/bin/bash
release-default: installgoreleaser ## Releases new project version using `goreleaser`
	if [ -z "$(PROJECT_URL)" ] ; then
		echo 'ERROR: Makefile variable PROJECT_URL must be set in order to use the "release" target'
		exit 1
	fi
	goreleaser $(GORELEASER_OPTS)
