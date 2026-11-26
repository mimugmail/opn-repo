#!/bin/sh

set -eu

[ "$#" -eq 1 ] || {
	echo "Usage: $0 full|single" >&2
	exit 2
}

SCRIPTSDIR=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
PLUGINSDIR=$(CDPATH='' cd -- "${SCRIPTSDIR}/.." && pwd)
TMPDIR_BASE=$(mktemp -d "${TMPDIR:-/tmp}/opn-catalog-ci.XXXXXX")

cleanup()
{
	[ -d "${TMPDIR_BASE}" ] || return 0
	rm -rf "${TMPDIR_BASE}"
}

trap cleanup EXIT HUP INT TERM

case "$1" in
full)
	config_url=https://www.routerperformance.net/mimugmail.conf
	expected="${PLUGINSDIR}/.github/ci/catalog-plugins.txt"
	probe_packages=yes
	;;
single)
	config_url=https://www.routerperformance.net/mimugmail-single.conf
	expected="${PLUGINSDIR}/.github/ci/catalog-single-plugins.txt"
	probe_packages=no
	;;
*)
	echo "Usage: $0 full|single" >&2
	exit 2
	;;
esac

echo ">>> OPNsense version: $(/usr/local/sbin/opnsense-version -vH)"
echo ">>> FreeBSD package ABI: $(/usr/local/sbin/pkg config abi)"
echo ">>> Refreshing repository catalog from ${config_url}"
fetch -o /usr/local/etc/pkg/repos/mimugmail-ci.conf "${config_url}"
/usr/local/sbin/pkg update -f

/usr/local/sbin/pkg rquery -r mimugmail '%n' |
    LC_ALL=C sort -u > "${TMPDIR_BASE}/packages.txt"
awk '/^os-/' "${TMPDIR_BASE}/packages.txt" > "${TMPDIR_BASE}/plugins.txt"
grep -vE '^(#|[[:space:]]*$)' "${expected}" |
    LC_ALL=C sort -u > "${TMPDIR_BASE}/expected.txt"

package_count=$(wc -l < "${TMPDIR_BASE}/packages.txt" | tr -d ' ')
plugin_count=$(wc -l < "${TMPDIR_BASE}/plugins.txt" | tr -d ' ')
echo ">>> Catalog inventory: ${package_count} packages, ${plugin_count} os-* plugins."
cat "${TMPDIR_BASE}/plugins.txt"

comm -13 "${TMPDIR_BASE}/expected.txt" "${TMPDIR_BASE}/plugins.txt" \
    > "${TMPDIR_BASE}/unexpected.txt"
comm -23 "${TMPDIR_BASE}/expected.txt" "${TMPDIR_BASE}/plugins.txt" \
    > "${TMPDIR_BASE}/missing.txt"

if [ -s "${TMPDIR_BASE}/unexpected.txt" ] ||
    [ -s "${TMPDIR_BASE}/missing.txt" ]; then
	echo ">>> Published os-* catalog does not match ${expected}." >&2
	if [ -s "${TMPDIR_BASE}/unexpected.txt" ]; then
		echo "Unexpected entries:" >&2
		sed 's/^/  /' "${TMPDIR_BASE}/unexpected.txt" >&2
	fi
	if [ -s "${TMPDIR_BASE}/missing.txt" ]; then
		echo "Missing entries:" >&2
		sed 's/^/  /' "${TMPDIR_BASE}/missing.txt" >&2
	fi
	exit 1
fi

[ "${probe_packages}" = yes ] || exit 0

failed=
while IFS= read -r package; do
	[ -n "${package}" ] || continue
	echo ">>> Checking search and dependency closure for ${package}"
	if ! /usr/local/sbin/pkg search -q -r mimugmail "${package}" \
	    > "${TMPDIR_BASE}/search.txt"; then
		echo ">>> Catalog search failed for ${package}." >&2
		failed=yes
		continue
	fi
	if [ ! -s "${TMPDIR_BASE}/search.txt" ]; then
		echo ">>> No search result for ${package}." >&2
		failed=yes
		continue
	fi

	fetch_dir="${TMPDIR_BASE}/fetch/${package}"
	mkdir -p "${fetch_dir}"
	if ! /usr/local/sbin/pkg fetch -U -y -r mimugmail \
	    -o "${fetch_dir}" "${package}"; then
		echo ">>> Artifact fetch failed for ${package}." >&2
		failed=yes
		continue
	fi

	find "${fetch_dir}" -type f -name '*.pkg' -print |
	    LC_ALL=C sort > "${TMPDIR_BASE}/artifacts.txt"
	artifact_count=$(wc -l < "${TMPDIR_BASE}/artifacts.txt" | tr -d ' ')
	if [ "${artifact_count}" -ne 1 ]; then
		echo ">>> Expected one artifact for ${package}; got ${artifact_count}." >&2
		failed=yes
		continue
	fi
	artifact=$(sed -n '1p' "${TMPDIR_BASE}/artifacts.txt")
	if ! /usr/local/sbin/pkg info -F "${artifact}" >/dev/null; then
		echo ">>> Artifact metadata validation failed for ${package}." >&2
		failed=yes
		continue
	fi

	# Keep dependency resolution open to every enabled repository.
	if ! /usr/local/sbin/pkg install -n -y -U "${artifact}"; then
		echo ">>> Dependency closure failed for ${package}." >&2
		failed=yes
	fi
done < "${TMPDIR_BASE}/expected.txt"

[ -z "${failed}" ] || exit 1
