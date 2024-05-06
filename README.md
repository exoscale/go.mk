# go.mk

## Introduction

This repository is an attempt to act as a GNU make common ground for exoscale's Go projects.


## Installation

### Requirements

You need to use GNU make (also known as `gmake`) version 3.82+, ideally 4+.


### Adding `go.mk` to your repo

There are two ways to use `go.mk` in your project.
You can either use it as a git submodule or configure your Makefile to pull and update go.mk automatically.
We recommend the Makefile approach.
It has the advantage that if you update `go.mk` to a newer version, make will automatically ensure the newer version is pulled and you don't need to run any extra git submodule commands.

#### Adding `go.mk` as a git submodule

You need to add this repository as a submodule for your project:

    git submodule add git@github.com:exoscale/go.mk.git


For more information about git submodules please refer to the documentation
page :

- https://git-scm.com/book/en/v2/Git-Tools-Submodules

#### Configuring make to pull `go.mk`

Add a line with `/go.mk` to your `.gitignore` file and
add the following lines at the top of your `Makefile`(or create it):

``` makefile
GO_MK_REF := v1.0.0

# make go.mk a dependency for all targets
.EXTRA_PREREQS = go.mk

ifndef MAKE_RESTARTS
# This section will be processed the first time that make reads this file.

# This causes make to re-read the Makefile and all included
# makefiles after go.mk has been cloned.
Makefile:
	@touch Makefile
endif

.PHONY: go.mk
.ONESHELL:
go.mk:
	@if [ ! -d "go.mk" ]; then
		git clone https://github.com/exoscale/go.mk.git
	fi
	@cd go.mk
	@if ! git show-ref --quiet --verify "refs/heads/${GO_MK_REF}"; then
		git fetch
	fi
	@if ! git show-ref --quiet --verify "refs/tags/${GO_MK_REF}"; then
		git fetch --tags
	fi
	git checkout --quiet ${GO_MK_REF}
```

You can replace the `GO_MK_REF` variable with whatever version tag, commit or branch of `go.mk` that you would like to use.
If you need to debug `go.mk` or for some reason don't want it to update automatically each time you run a make command, you can set `GO_MK_REF` to `HEAD`.

### Initializing go.mk

If you are using `go.mk` as a submodule add this to your `Makefile`:

    include go.mk/init.mk

If you are using the `Makefile`-only approach you need an extra line:

    go.mk/init.mk:
    include go.mk/init.mk

(Make sure to add every included file this way or `make` will error)

If `Makefile` is in a subdirectory:

    INCLUDE_PATH=../go.mk
    include $(INCLUDE_PATH)/init.mk

You can test your setup is OK by running either `make help` or `make dumpvariables`.

The output of `make help` should look like this:

    build                          Builds a go binary in silent mode
    build-verbose                  Builds a go binary in verbose mode
    clean                          Removes compiled go binaries
    dumpvariables                  Dump configuration variables
    help                           Shows this help
    installgolangcilint            Installs golangcilint (https://golangci.com/)
    lint                           Lint go code
    test                           Run go tests in silent mode
    test-verbose                   Run go tests in verbose mode
    vet                            Run go vet

The output of `make dumpvariables` should look like this:

    MAKE_VERSION            = 4.2.1
    OS                      = linux
    ARCH                    = x86_64
    SED                     = /usr/bin/sed

    INCLUDE_PATH            = /home/jerome/.go/src/github.com/[...]/go.mk

    GIT_REVISION            = 6f65b95
    GIT_BRANCH              = snapshotmgr/jenkins
    VERSION                 = dev

    GO                      = /usr/local/go/bin/go
    GO_LD_FLAGS             = -ldflags -X main.gitCommit=6f65b95 -X main.gitBranch=snapshotmgr/jenkins -X main.buildDate=2020-01-31T14:04:56+0000 -X main.version=dev
    GO_PKGS                 = github.com/exoscale/storage-copilot/cmd/snapshotmgr github.com/exoscale/storage-copilot/cmd/snapshotmgr/config [...]
    GO_TEST_PKGS            = github.com/exoscale/storage-copilot/cmd/snapshotmgr/config github.com/exoscale/storage-copilot/cmd/snapshotmgr/file [...]
    GO_TEST_TIMEOUT         = 15s
    GO_TAGS                 = 
    GO_BIN_OUTPUT_DIR       = /home/jerome/.go/src/github.com/[...]/bin


### Updating the submodule

If ever you want to fetch new changes in `go.mk` and the git submodule is
already installed, you can simply fetch updates by using the following command:

    git submodule update --remote go.mk


## Configuration

Almost all variables dumped when running `make dumpvariables` can be overriden
either from the command line of from your `Makefile`.

Here is how to override a variable from the command line:

    ➜ GO=foobar make dumpvariables

    [...]
    GO = foobar
    [...]

Or in your `Makefile`:

    GO="foobar"

    include go.mk/init.mk

And then:

    ➜ make dumpvariables

    [...]
    GO = foobar
    [...]

Any variable you want to override must be declared BEFORE including `go.mk/init.mk`


### "Public" targets

If a *public* project (i.e. Open Source project repository hosted in a public
GitHub) uses `go.mk`, it can include the `public.mk` Makefile to access
public-only targets such as `release`, that calls [GoReleaser][goreleaser] in
order to handle releases of the project according to the configuration set in
the `.goreleaser.yml` file.

    include ./go.mk/init.mk
    include ./go.mk/public.mk

And then:

    ➜ make git-tag
      # Set a new Git tag
    ➜ git push --tags
    ➜ make release
      [...]


#### `release`

The `release` target requires a `PROJECT_URL` Makefile variable set to the HTTP
URL of the project repository, e.g. `https://github.com/alice/cool_project`.

## Extendable targets

An extendable target is a `make` target (`build`, `vet`, `lint` ...) which can
be extended in your own Makefile. Which means that for target `foo` when you
run `make foo` the target `foo` in `go.mk` will be called first and then the
target `foo` you declared in your `Makefile`.

Right now the only available extendable target is the `clean` target. However
if you need other targets feel free to shoot a PR for this. Transforming a
standard target is as simple as appending `:` at the end of the target. For
example:

- `clean:` -> not extendable
- `clean::` -> extendable

Example on how to extend the `clean` target:


    include ./go.mk/init.mk

    clean::
        @echo "I will be called as well"

And then call `make clean` and you should see something like this:

    rm -rf [...]
    I will be called as well


[goreleaser]: https://goreleaser.com/
