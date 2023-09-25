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
if [ ! "${artifact##*.}" = "deb" ]; then
    exit 0
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

# customize aptly.conf
sed -i "s/PLACEHOLDER_FOR_BUCKETNAME/$bucketname/" "$aptlyconfig"
sed -i "s/PLACEHOLDER_FOR_ZONE/$zone/" "$aptlyconfig"
sed -i "s/PLACEHOLDER_FOR_PREFIX/${repoprefixescaped}/" "$aptlyconfig"

# Get the 10 latest Git tags
latest_tags=$(git tag --sort=-v:refname | head -n $nrversionstokeep)

# Create a package query filter for aptly
package_filter=""
for tag in $latest_tags; do
    stripped_tag=$(expr "$tag" : '.\(.*\)')
    if [ $first_tag_set ]; then
        package_filter+=" | "
    fi
    package_filter+="exoscale-cli (= $stripped_tag)"
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

$aptlycmd repo create $aptlyrepo

if mirrorrepo; then
    $aptlycmd repo import $aptlymirror $aptlyrepo "$package_filter"
fi

$aptlycmd repo add $aptlyrepo $artifact

$aptlycmd publish repo \
    $gpgkeyflag \
    -distribution=$aptlydistro \
    $aptlyrepo \
    $aptlyremote

# this step cleans up package files that are unreferenced
$aptlycmd publish update \
    $aptlydistro \
    $aptlyremote
