#!/bin/sh

set -eu

SCRIPTSDIR=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
PLUGINSDIR=$(CDPATH='' cd -- "${SCRIPTSDIR}/.." && pwd)

usage()
{
	echo "Usage: $0 --base <commit> --head <commit>" >&2
	exit 2
}

base=${BASE_SHA-}
head=${HEAD_SHA-}

while [ "$#" -gt 0 ]; do
	case "$1" in
	--base)
		[ "$#" -ge 2 ] || usage
		base=$2
		shift 2
		;;
	--head)
		[ "$#" -ge 2 ] || usage
		head=$2
		shift 2
		;;
	*)
		usage
		;;
	esac
done

[ -n "${base}" ] && [ -n "${head}" ] || usage

cd "${PLUGINSDIR}"

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/opn-host-ci.XXXXXX")
cleanup()
{
	rm -f "${tmp_dir}/shell-files" "${tmp_dir}/yaml-files"
	rmdir "${tmp_dir}"
}
trap cleanup EXIT HUP INT TERM

find . \
    \( -path './.git' -o -path '*/work' \) -prune -o \
    -type f -name '*.sh' -print > "${tmp_dir}/shell-files"
while IFS= read -r script; do
	sh -n "${script}"
done < "${tmp_dir}/shell-files"

find .github -type f \( -name '*.yml' -o -name '*.yaml' \) \
    -print > "${tmp_dir}/yaml-files"
while IFS= read -r yaml; do
	ruby -e 'require "yaml"; YAML.load_file(ARGV.fetch(0))' "${yaml}"
done < "${tmp_dir}/yaml-files"

git rev-parse --verify "${base}^{commit}" >/dev/null
git rev-parse --verify "${head}^{commit}" >/dev/null
base=$(git merge-base "${base}" "${head}")
git diff --check "${base}" "${head}"

if [ "${CI_SKIP_SELF_TESTS-}" != 1 ]; then
	Scripts/ci-self-tests.sh
fi

cleanup
trap - EXIT HUP INT TERM
