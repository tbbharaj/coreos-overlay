# Copyright (c) 2015 The CoreOS OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=5
CROS_WORKON_PROJECT="flatcar-linux/seismograph"
CROS_WORKON_REPO="git://github.com"
AUTOTOOLS_AUTORECONF=1

if [[ "${PV}" == 9999 ]]; then
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
else
	CROS_WORKON_COMMIT="1729ecfda5c88fbcd72c1547990fbdcd51a2de08"
	KEYWORDS="amd64 arm arm64 x86"
fi

inherit autotools-utils cros-workon

DESCRIPTION="CoreOS Disk Utilities (e.g. cgpt)"
LICENSE="BSD"
SLOT="0"
IUSE=""

RDEPEND="!coreos-base/vboot_reference
	!sys-apps/rootdev
	sys-apps/util-linux
	sys-fs/e2fsprogs"
DEPEND="${RDEPEND}"
