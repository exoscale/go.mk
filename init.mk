_VERSION_DIGIT := $(shell expr substr $(shell printf '%s%01d' $(shell echo '$(MAKE_VERSION)' | tr -d .)) 1 3)
_VERSION_COMPARE := $(shell echo $$(( $(_VERSION_DIGIT) >= 382)))

ifeq ($(_VERSION_COMPARE),0)
$(error "Your Make version ($(MAKE_VERSION)) is too old. Gnu make 3.8.2+ is required, 4+ recommended.")
endif

# ---

ifndef INCLUDE_PATH
	ifeq ($(notdir $(PWD)), go.mk)
		INCLUDE_PATH := $(PWD)
	else
		INCLUDE_PATH := $(PWD)/go.mk
	endif
endif

include $(INCLUDE_PATH)/version.mk
include $(INCLUDE_PATH)/os.mk
include $(INCLUDE_PATH)/go.mk

# ---

.DEFAULT: help

all: help

# ---


.PHONY: dumpvariables
dumpvariables: ## Dump configuration variables
	@echo "MAKE_VERSION            = $(MAKE_VERSION)"
	@echo "OS                      = $(OS)"
	@echo "ARCH                    = $(ARCH)"
	@echo "SED                     = $(SED)"
	@echo ""
	@echo "INCLUDE_PATH            = $(INCLUDE_PATH)"
	@echo ""
	@echo "GIT_REVISION            = $(GIT_REVISION)"
	@echo "GIT_BRANCH              = $(GIT_BRANCH)"
	@echo "VERSION                 = $(VERSION)"
	@echo ""
	@echo "GO                      = $(GO)"
	@echo "GO_LD_FLAGS             = $(GO_LD_FLAGS)"
	@echo "GO_PKGS                 = $(GO_PKGS)"
	@echo "GO_TEST_PKGS            = $(GO_TEST_PKGS)"
	@echo "GO_TEST_TIMEOUT         = $(GO_TEST_TIMEOUT)"
	@echo "GO_TAGS                 = $(GO_TAGS)"
	@echo "GO_BIN_OUTPUT_DIR       = $(GO_BIN_OUTPUT_DIR)"


.PHONY: help
help: ## Shows this help
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
