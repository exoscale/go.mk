GO_COVERAGE_DIR ?= $(CURDIR)/coverage

# ---

.PHONY: test-coverage
.ONESHELL:
test-coverage: $(GO_COVERAGE_DIR) run-test-with-coverage gen-coverage-profiles ## Run tests with coverage enabled


.PHONY: $(GO_COVERAGE_DIR)
$(GO_COVERAGE_DIR):
	test -d $(GO_COVERAGE_DIR) || mkdir $(GO_COVERAGE_DIR)


.PHONY: run-test-with-coverage
.ONESHELL:
run-test-with-coverage:
	for pkg in $(GO_TEST_PKGS); do
		$(GO) test            			\
			-race             			\
			-cover            			\
			-timeout $(GO_TEST_TIMEOUT) \
			-coverpkg=./...   			\
			-covermode=atomic 			\
			-coverprofile="$(GO_COVERAGE_DIR)/`echo $$pkg | tr "/" "-"`.out" $$pkg
	done


GO_COVERAGE_OUTPUT_MERGED = $(GO_COVERAGE_DIR)/all.out
GO_COVERAGE_OUTPUT_XML = $(GO_COVERAGE_DIR)/coverage.xml
GO_COVERAGE_OUTPUT_HTML = $(GO_COVERAGE_DIR)/index.html
.PHONY: gen-coverage-profiles
.ONESHELL:
gen-coverage-profiles: install-coverage-requirements
	gocovmerge $(GO_COVERAGE_DIR)/*.out > $(GO_COVERAGE_OUTPUT_MERGED)
	$(GO) tool cover -html=$(GO_COVERAGE_OUTPUT_MERGED) -o $(GO_COVERAGE_OUTPUT_HTML)
	gocov convert $(GO_COVERAGE_OUTPUT_MERGED) | gocov-xml > $(GO_COVERAGE_OUTPUT_XML)
	rm $(GO_COVERAGE_DIR)/*.out


.PHONY:
.ONESHELL:
install-coverage-requirements:
	export GO111MODULE=off
	which gocov      > /dev/null || go get github.com/axw/gocov/gocov
	which gocov-xml  > /dev/null || go get github.com/AlekSi/gocov-xml
	which gocovmerge > /dev/null || go get github.com/wadey/gocovmerge


clean::
	rm -rf $(GO_COVERAGE_DIR)
