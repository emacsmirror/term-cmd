# shellcheck shell=bash

set -eu

TEMPLATE_DIR='@templateDir@'
REPO='@repo@'

if ! REF="$(echo "${DEVENV_TASK_INPUT}" | jq --raw-output --exit-status .ref)" || [ -z "${REF}" ]; then
    REF="$(git ls-remote --exit-code --tags --refs --sort 'v:refname' "${REPO}" | tail -n 1 | cut -f 2 | sed 's|refs/tags/||g')"
fi

git subtree pull --prefix "${TEMPLATE_DIR}" --squash "${REPO}" "${REF}"
