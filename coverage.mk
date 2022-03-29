## GoLang tests coverage

GO_COVERAGE_DIR ?= $(CURDIR)/coverage

GOCOV ?= $(shell which gocov)
GOCOV_XML ?= $(shell which gocov-xml)
GOCOVMERGE ?= $(shell which gocovmerge)


## Targets

# Dependencies

.PHONY:
install-coverage-requirements:
	GO111MODULE=off '$(GO)' get github.com/axw/gocov/gocov
	GO111MODULE=off '$(GO)' get github.com/AlekSi/gocov-xml
	GO111MODULE=off '$(GO)' get github.com/wadey/gocovmerge

# Coverage

.PHONY: test-coverage
test-coverage: $(GO_COVERAGE_DIR) run-test-with-coverage gen-coverage-profiles

$(GO_COVERAGE_DIR):
	mkdir -p '$(GO_COVERAGE_DIR)'

.PHONY: run-test-with-coverage
run-test-with-coverage:
	for pkg in $(GO_TEST_PKGS); do \
	  '$(GO)' test \
	    -race \
	    -cover \
	    -timeout $(GO_TEST_TIMEOUT) \
	    -coverpkg=./... \
	    -covermode=atomic \
	    -coverprofile="$(GO_COVERAGE_DIR)/$$(echo $${pkg} | tr '/' '-').out" "$${pkg}"; \
	done

GO_COVERAGE_OUTPUT_MERGED = $(GO_COVERAGE_DIR)/all.out
GO_COVERAGE_OUTPUT_XML = $(GO_COVERAGE_DIR)/coverage.xml
GO_COVERAGE_OUTPUT_HTML = $(GO_COVERAGE_DIR)/index.html
.PHONY: gen-coverage-profiles
gen-coverage-profiles $(GO_COVERAGE_OUTPUT_HTML): install-coverage-requirements
	'$(GOCOVMERGE)' '$(GO_COVERAGE_DIR)'/*.out > '$(GO_COVERAGE_OUTPUT_MERGED)'
	'$(GO)' tool cover -html '$(GO_COVERAGE_OUTPUT_MERGED)' -o '$(GO_COVERAGE_OUTPUT_HTML)'
	'$(GOCOV)' convert '$(GO_COVERAGE_OUTPUT_MERGED)' | '$(GOCOV_XML)' > '$(GO_COVERAGE_OUTPUT_XML)'
	rm -f '$(GO_COVERAGE_DIR)'/*.out
	@echo Please visit '$(GO_COVERAGE_DIR)/index.html'

# Clean

clean::
	rm -rf '$(GO_COVERAGE_DIR)'
