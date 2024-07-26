#!/usr/bin/env sh

CURRENT_TAG=$1

INITIAL_COMMIT=$(git rev-list --max-parents=0 HEAD)

PREVIOUS_TAG=$(git tag | sort --version-sort --reverse | awk "/^${CURRENT_TAG}$/ {getline; print}")

if [ "${PREVIOUS_TAG}" = "${CURRENT_TAG}" ]; then
    PREVIOUS_TAG=${INITIAL_COMMIT}
fi

printf "\n## %s\n" ${CURRENT_TAG}

git log ${PREVIOUS_TAG}..${CURRENT_TAG} --oneline --no-decorate
