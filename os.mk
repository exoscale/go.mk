ifeq ($(shell uname -s),Darwin)
	OS := darwin
	ARCH := amd64
	SED := $(shell which gsed)
else
	OS := $(shell uname -s | awk '{print tolower($$0)}')
	ARCH := $(shell uname -p)
	SED := $(shell which sed)
endif
