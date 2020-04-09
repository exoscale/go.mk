_VERSION := $(shell git describe --exact-match --tags $(git log -n1 --pretty='%h') 2> /dev/null | sed 's/^v//')
ifndef _VERSION
    _VERSION = dev
endif

GIT_BRANCH := 	$(shell git rev-parse --abbrev-ref HEAD || echo 'n/a')

GIT_REVISION :=	$(shell git rev-parse --short HEAD || echo 'n/a')
