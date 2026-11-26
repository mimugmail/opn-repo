#!/bin/sh

set -eu

SCRIPTSDIR=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
PLUGINSDIR=$(CDPATH='' cd -- "${SCRIPTSDIR}/.." && pwd)
COREDIR=$(CDPATH='' cd -- "${PLUGINSDIR}/.." && pwd)/core
CORE_REF=4092e306ab6cfa9748875053fbb41c4c7cd5af2d
CORE_BRANCH=stable/26.7

[ ! -e "${COREDIR}" ] || {
	echo ">>> Refusing to replace adjacent core checkout: ${COREDIR}" >&2
	exit 1
}

echo ">>> Checking out OPNsense core ${CORE_BRANCH} at ${CORE_REF}"
git clone --filter=blob:none --no-checkout \
    --single-branch --branch "${CORE_BRANCH}" \
    https://github.com/opnsense/core.git "${COREDIR}"
git -C "${COREDIR}" checkout --detach "${CORE_REF}"

actual_ref=$(git -C "${COREDIR}" rev-parse HEAD)
[ "${actual_ref}" = "${CORE_REF}" ] || {
	echo ">>> Core checkout is ${actual_ref}, expected ${CORE_REF}." >&2
	exit 1
}

echo ">>> Enabling the full binary repository for runtime build dependencies."
fetch -o /usr/local/etc/pkg/repos/mimugmail.conf \
    https://www.routerperformance.net/mimugmail.conf
/usr/local/sbin/pkg update -f

cd "${PLUGINSDIR}"
Scripts/ci-packages.sh run
