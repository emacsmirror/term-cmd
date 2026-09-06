#!/usr/bin/env bash

set -eu

REPO='@repo@'

function fail() {
    echo "${@}" >&2
    exit 1
}

function usage() {
    fail "Usage: $(basename "${0}") [ref]"
}

test "${#}" -gt 1 && usage

if [ -n "${1:-}" ]; then
    REF="${1}"
else
    REF="$(git ls-remote --exit-code --tags --refs --sort 'v:refname' "${REPO}" | tail -n 1 | cut -f 2 | sed 's|refs/tags/||g')"
fi

if [ -z "${REF}" ]; then
    fail "Error: cannot find any tags in the source repo, specify a ref manually"
fi

TEMPLATE_DIR='@templateDir@'
ENVRC='.envrc'
DEVENV_NIX='devenv.nix'
DEVENV_YAML='devenv.yaml'

function fail-if-exists() {
    if [ -e "${1}" ]; then
        fail "Error: '${1}' already exists"
    fi
}

fail-if-exists "${TEMPLATE_DIR}"
fail-if-exists "${ENVRC}"
fail-if-exists "${DEVENV_NIX}"
fail-if-exists "${DEVENV_YAML}"

git subtree add --prefix "${TEMPLATE_DIR}" --squash "${REPO}" "${REF}"

YEAR="$(date '+%Y')"

cat >"${DEVENV_NIX}" <<EOF
{ ... }: {
  template = {
    project = {
      name = "TODO";
      author = "TODO";
      version = "0.0.0";
      copyrightYears = {
        start = "${YEAR}";
        end = "${YEAR}";
      };
    };
  };
}
EOF

cat >"${DEVENV_YAML}" <<EOF
# yaml-language-server: \$schema=https://devenv.sh/devenv.schema.json
inputs:
  nixpkgs:
    url: github:cachix/devenv-nixpkgs/rolling

imports:
  - /${TEMPLATE_DIR}/template
EOF

cat >"${ENVRC}" <<'EOF'
#!/usr/bin/env bash

eval "$(devenv direnvrc)"

# You can pass flags to the devenv command
# For example: use devenv --impure --option services.postgres.enable:bool true
use devenv
EOF
