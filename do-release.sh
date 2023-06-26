#!/usr/bin/env sh

set -e

git clone https://github.com/sauterp/cli.git
cd cli
git checkout sauterp/sc-42833/cli-release

# TODO(sauterp) remove this line
git tag 1.70.1$BUILD_NUMBER
git submodule update --init --recursive go.mk

docker login --username philippsauterexoscale --password $DOCKERHUB_ACCESS_TOKEN

export CGO_ENABLED=1
make release
