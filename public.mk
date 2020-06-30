.PHONY: release
release: SHELL:=/bin/bash
release:
	goreleaser --release-notes <(echo "See the [CHANGELOG](https://$(PACKAGE)/blob/v$(VERSION)/CHANGELOG.md) for details.")
