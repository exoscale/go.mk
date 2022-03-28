## Public projects

ifndef INCLUDE_PATH
	ifeq ($(notdir $(PWD)), go.mk)
		INCLUDE_PATH := $(PWD)
	else
		INCLUDE_PATH := $(PWD)/go.mk
	endif
endif

# Dependencies

include $(INCLUDE_PATH)/release.mk
