#!/usr/bin/env sh

# this script assumes, you are running it from the parent directory of this repository

# TODO (sc-78178) revert
set -ex
#set -e

artifact=$1
bucketname=$2
repoprefix=$3
if [ -z "$4" ]; then
    nrversionstokeep=10
else
    nrversionstokeep=$4
fi

# Check if the artifact ends with ".rpm"
if [ "${artifact%%.rpm}" = "${artifact}" ]; then
    exit 0
fi

# goreleaser executes this script in parallel for each artifact but S3 repos can't be updated in parallel
(
    # Acquire an exclusive lock on the lock file, or wait until it's available
    flock -w 1200 8 || exit 1

    if ! command -v createrepo_c || ! command -v rclone; then
        sudo apt-get update
        sudo apt-get install -y createrepo-c rclone
    fi

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

    # we only want to keep a limited number of versions of the package
    # therefore we have to list, sort and then delete older versions
    pkgname=$(echo $artifact | sed -n 's|.*/\(.*\)_[0-9]*\.[0-9]*\.[0-9]*_linux_.*\.rpm|\1|p')
    pkgarch=$(echo $artifact | sed -n 's|.*/.*_[0-9]*\.[0-9]*\.[0-9]*_linux_\(.*\)\.rpm|\1|p')

    sorted_files="$(ls ${repodir}/${pkgname}_*_linux_${pkgarch}.rpm | sort --version-sort --reverse)"

    # Get the count of all files
    file_count=$(echo "$sorted_files" | wc -l)

    # Calculate the number of files to delete
    delete_count=$((${file_count} - ${nrversionstokeep}))

    if [ $delete_count -gt 0 ]; then
        # delete some older versions
        echo "$sorted_files" | head -n $delete_count | xargs -d '\n' rm -f --
    fi

    createrepo_c "${repodir}"
    filetosign=${repodir}/repodata/repomd.xml

    # remove the old signature if it exists
    rm -f ${filetosign}.asc
    # TODO (sc-78178) uncomment
    # gpg --default-key=7100E8BFD6199CE0374CB7F003686F8CDE378D41 --detach-sign --armor $filetosign

    $rclonecmd sync -vv -P ${repodir} "${reponame}:${bucketname}/${repoprefix}"

    sync
) 8>/tmp/publish-rpm-artifact-to-sos.lock

rm -f /tmp/publish-rpm-artifact-to-sos.lock
