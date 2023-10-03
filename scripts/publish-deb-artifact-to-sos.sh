#!/usr/bin/env sh

# this script assumes, you are running it from the parent directory of this repository

set -e

artifact=$1
bucketname=$2
repoprefix=$3
repoprefixescaped=$(echo $repoprefix | sed 's#/#\\\/#g')
if [ -z "$4" ]; then
    nrversionstokeep=10
else
    nrversionstokeep=$4
fi

# Check if the artifact ends with ".deb"
if [ "${artifact%%.deb}" = "${artifact}" ]; then
    exit 0
fi

# The apt package manager only recognizes 'armhf' as a value for armv6 and armv7 packages.
# Since armv6 binaries will run on armv7 cpus, we only publish the armv6 package as the
# apt repo cannot have two packages for the 'same' armhf architecture
if [ "${artifact%%armv7.deb}" != "${artifact}" ]; then
    echo "not publishing armv7 package for debian in favor of armv6 package"
    exit 0
fi

# goreleaser executes this script in parallel for each artifact but aptly repos can't be updated in parallel
(
    # Acquire an exclusive lock on the lock file, or wait until it's available
    flock -w 1200 9 || exit 1

    # install aptly if not available
    if ! command -v aptly; then
        sudo apt-get update
        sudo apt-get install -y aptly
    fi

    aptlyrepo=release-repo
    aptlyremote="s3:${bucketname}:"
    zone="ch-gva-2"
    archiveurl=https://sos-${zone}.exo.io/${bucketname}/${repoprefix}
    aptlymirror=${aptlyrepo}-mirror
    aptlydistro=stable
    aptlyconfig="go.mk/scripts/aptly.conf"
    aptlycmd="aptly -config=$aptlyconfig"
    gpgkeyflag='-gpg-key=7100E8BFD6199CE0374CB7F003686F8CDE378D41'
    archflag='-architectures=amd64,arm64,armhf'

    # customize aptly.conf
    sed -e "s/PLACEHOLDER_FOR_BUCKETNAME/$bucketname/" \
        -e "s/PLACEHOLDER_FOR_ZONE/$zone/" \
        -e "s/PLACEHOLDER_FOR_PREFIX/${repoprefixescaped}/" ${aptlyconfig}.template >$aptlyconfig

    # Get the 10 latest Git tags
    latest_tags=$(git tag --sort=-v:refname | head -n $nrversionstokeep)

    # Create a package query filter for aptly
    package_filter=""
    for tag in $latest_tags; do
        stripped_tag=$(expr "$tag" : '.\(.*\)')
        if [ $first_tag_set ]; then
            package_filter="${package_filter} | "
        fi
        package_filter="${package_filter} exoscale-cli (= ${stripped_tag})"
        first_tag_set=1
    done

    mirrorrepo() {
        $aptlycmd mirror create \
            $aptlymirror \
            $archiveurl \
            $aptlydistro

        $aptlycmd mirror update \
            $aptlymirror
    }

    if ! $aptlycmd repo show $aptlyrepo 2>/dev/null; then
        isrepounpublished=1

        $aptlycmd repo create $aptlyrepo

        if mirrorrepo; then
            $aptlycmd repo import $aptlymirror $aptlyrepo "$package_filter"
        fi
    fi

    $aptlycmd repo add \
        $aptlyrepo \
        $artifact

    if [ $isrepounpublished ]; then
        $aptlycmd publish repo \
            $gpgkeyflag \
            $archflag \
            -distribution=$aptlydistro \
            $aptlyrepo \
            $aptlyremote
    fi

    # this step cleans up package files that are unreferenced
    $aptlycmd publish update \
        $gpgkeyflag \
        $archflag \
        $aptlydistro \
        $aptlyremote

) 9>/tmp/publish-deb-artifact-to-sos.lock

rm -f /tmp/publish-deb-artifact-to-sos.lock
