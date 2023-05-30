#!/bin/bash

set -euo pipefail

UPDATE_NEEDED=1

. .github/workflows/common.sh

prepare_git_repo

if ! checkout_branches "${VERSION_NEW}-${TARGET}"; then
  UPDATE_NEEDED=0
  exit 0
fi

pushd "${SDK_OUTER_SRCDIR}/third_party/coreos-overlay" >/dev/null || exit

# Parse the Manifest file for already present source files and keep the latest version in the current series
VERSION_OLD=$(sed -n "s/^DIST linux-firmware-\([0-9]*\).*$/\1/p" sys-kernel/coreos-firmware/Manifest | sort -ruV | head -n1)
if [[ "${VERSION_NEW}" = "${VERSION_OLD}" ]]; then
  echo "already the latest Linux Firmware, nothing to do"
  UPDATE_NEEDED=0
  exit 0
fi

EBUILD_FILENAME=$(get_ebuild_filename "sys-kernel" "coreos-firmware" "${VERSION_OLD}")
git mv "${EBUILD_FILENAME}" "sys-kernel/coreos-firmware/coreos-firmware-${VERSION_NEW}.ebuild"

popd >/dev/null || exit

URL="https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tag/?h=${VERSION_NEW}"

generate_update_changelog 'Linux Firmware' "${VERSION_NEW}" "${URL}" 'linux-firmware'

generate_patches sys-kernel coreos-firmware "Linux Firmware"

apply_patches

echo "VERSION_OLD=${VERSION_OLD}" >>"${GITHUB_OUTPUT}"
echo "UPDATE_NEEDED=${UPDATE_NEEDED}" >>"${GITHUB_OUTPUT}"
