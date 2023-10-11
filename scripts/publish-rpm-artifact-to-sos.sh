#!/usr/bin/env sh

# this script assumes, you are running it from the parent directory of this repository

set -e

artifact=$1
bucketname=$2
repoprefix=$3

# Check if the artifact ends with ".rpm"
if [ "${artifact%%.rpm}" = "${artifact}" ]; then
    exit 0
fi

# goreleaser executes this script in parallel for each artifact but S3 repos can't be updated in parallel
(
    # Acquire an exclusive lock on the lock file, or wait until it's available
    flock -w 1200 9 || exit 1

    if ! command -v createrepo_c || ! command -v rclone; then
        sudo apt-get update
        sudo apt-get install -y createrepo_c rclone
    fi

    # Get the 10 latest Git tags
    # latest_tags=$(git tag --sort=-v:refname | head -n $nrversionstokeep)

    # Create a package query filter for aptly
    # package_filter=""
    # for tag in $latest_tags; do
    #     stripped_tag=$(expr "$tag" : '.\(.*\)')
    #     if [ $first_tag_set ]; then
    #         package_filter="${package_filter} | "
    #     fi
    #     package_filter="${package_filter} exoscale-cli (= ${stripped_tag})"
    #     first_tag_set=1
    # done

    # TODO (sc-78178) only keep last 10 versions

    reponame=rpmrepo
    # TODO (sc-78178) remove sauterp
    bucketname=sauterp-exoscale-packages
    repodir=./rpmrepo/
    rcloneconf=./rclone.config
    rclonecmd="rclone --config=${rcloneconf}"
    # TODO (sc-78178) customize
    #     zone="ch-gva-2"
    #     archiveurl=https://sos-${zone}.exo.io/${bucketname}/${repoprefix}
    $rclonecmd config create $reponame s3 provider Other env_auth true endpoint sos-ch-gva-2.exo.io location_constraint ch-gva-2 acl public-read

    mkdir -p $repodir
    $rclonecmd sync -vv -P $reponame:${bucketname}/$repoprefix $repodir

    cp $artifact $repodir
    createrepo_c $repodir
    gpg --default-key=7100E8BFD6199CE0374CB7F003686F8CDE378D41 --detach-sign --armor ${repodir}/repodata/repomd.xml

    $rclonecmd sync -vv -P $repodir $reponame:${bucketname}/$repoprefix
) 9>/tmp/publish-rpm-artifact-to-sos.lock

rm -f /tmp/publish-rpm-artifact-to-sos.lock
