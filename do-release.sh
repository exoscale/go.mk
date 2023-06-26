#!/usr/bin/env sh

set -e

git clone git@github.com:sauterp/cli.git
git checkout sauterp/sc-42833/cli-release
git submodule update --init --recursive go.mk

export CGO_ENABLED=1
make release
