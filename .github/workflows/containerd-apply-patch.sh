#!/bin/bash

set -euo pipefail

UPDATE_NEEDED=1

. .github/workflows/common.sh

prepare_git_repo

if ! checkout_branches "containerd-${VERSION_NEW}-${TARGET}"; then
  UPDATE_NEEDED=0
  exit 0
fi

pushd "${SDK_OUTER_SRCDIR}/third_party/coreos-overlay" >/dev/null || exit

VERSION_OLD=$(sed -n "s/^DIST containerd-\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p" app-emulation/containerd/Manifest | sort -ruV | head -n1)
if [[ "${VERSION_NEW}" = "${VERSION_OLD}" ]]; then
  echo "already the latest Containerd, nothing to do"
  UPDATE_NEEDED=0
  exit 0
fi

DOCKER_VERSION=$(sed -n "s/^DIST docker-\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p" app-emulation/docker/Manifest | sort -ruV | head -n1)

# we need to update not only the main ebuild file, but also its CONTAINERD_COMMIT,
# which needs to point to COMMIT_HASH that matches with $VERSION_NEW from upstream containerd.
containerdEbuildOldSymlink=$(get_ebuild_filename "app-emulation" "containerd" "${VERSION_OLD}")
containerdEbuildNewSymlink="app-emulation/containerd/containerd-${VERSION_NEW}.ebuild"
containerdEbuildMain="app-emulation/containerd/containerd-9999.ebuild"
git mv ${containerdEbuildOldSymlink} ${containerdEbuildNewSymlink}
sed -i "s/CONTAINERD_COMMIT=\"\(.*\)\"/CONTAINERD_COMMIT=\"${COMMIT_HASH}\"/g" ${containerdEbuildMain}
sed -i "s/v${VERSION_OLD}/v${VERSION_NEW}/g" ${containerdEbuildMain}

# torcx ebuild file has a docker version with only major and minor versions, like 19.03.
versionTorcx=${DOCKER_VERSION%.*}
torcxEbuildFile=$(ls -1 app-torcx/docker/docker-${versionTorcx}*.ebuild | sort -ruV | head -n1)
sed -i "s/containerd-${VERSION_OLD}/containerd-${VERSION_NEW}/g" ${torcxEbuildFile}

popd >/dev/null || exit

URL="https://github.com/containerd/containerd/releases/tag/v${VERSION_NEW}"

generate_update_changelog 'containerd' "${VERSION_NEW}" "${URL}" 'containerd'

generate_patches app-emulation containerd Containerd

apply_patches

echo "VERSION_OLD=${VERSION_OLD}" >>"${GITHUB_OUTPUT}"
echo "UPDATE_NEEDED=${UPDATE_NEEDED}" >>"${GITHUB_OUTPUT}"
