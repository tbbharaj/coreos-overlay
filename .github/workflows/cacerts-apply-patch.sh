#!/bin/bash

set -euo pipefail

. .github/workflows/common.sh

BRANCH_NAME="cacerts-${VERSION_NEW}-${TARGET}"

prepare_git_repo

if ! checkout_branches "${BRANCH_NAME}"; then
  exit 0
fi

pushd "${SDK_OUTER_SRCDIR}/third_party/coreos-overlay" >/dev/null || exit

# Parse the Manifest file for already present source files and keep the latest version in the current series
VERSION_OLD=$(sed -n "s/^DIST nss-\([0-9]*\.[0-9]*\).*$/\1/p" app-misc/ca-certificates/Manifest | sort -ruV | head -n1)
if [[ "${VERSION_NEW}" = "${VERSION_OLD}" ]]; then
  echo "already the latest ca-certificates, nothing to do"
  exit 0
fi

EBUILD_FILENAME=$(get_ebuild_filename "app-misc" "ca-certificates" "${VERSION_OLD}")
git mv "${EBUILD_FILENAME}" "app-misc/ca-certificates/ca-certificates-${VERSION_NEW}.ebuild"

popd >/dev/null || exit

URLVERSION=$(echo "${VERSION_NEW}" | tr '.' '_')
URL="https://firefox-source-docs.mozilla.org/security/nss/releases/nss_${URLVERSION}.html"

generate_update_changelog 'ca-certificates' "${VERSION_NEW}" "${URL}" 'ca-certificates'

generate_patches app-misc ca-certificates ca-certificates

apply_patches

echo "VERSION_OLD=${VERSION_OLD}" >>"${GITHUB_OUTPUT}"
echo "UPDATE_NEEDED=1" >>"${GITHUB_OUTPUT}"
echo "BRANCH_NAME=${BRANCH_NAME}" >>"${GITHUB_OUTPUT}"
