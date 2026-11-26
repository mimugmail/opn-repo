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
	rm -f "${tmp_dir}/shell-files" "${tmp_dir}/yaml-files" \
	    "${tmp_dir}/changed-shell-files" "${tmp_dir}/changed-files" \
	    "${tmp_dir}/baseline-old" "${tmp_dir}/baseline-new" \
	    "${tmp_dir}/baseline-added"
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

git diff --no-renames --diff-filter=ACMR --name-only "${base}" "${head}" -- \
    > "${tmp_dir}/changed-files"
if ! command -v shellcheck >/dev/null 2>&1; then
	echo ">>> shellcheck is required for the source submission gate." >&2
	exit 1
fi

find Scripts -type f -name '*.sh' -print \
    > "${tmp_dir}/changed-shell-files"
while IFS= read -r changed_file; do
	[ -f "${changed_file}" ] || continue
	case $(sed -n '1p' "${changed_file}") in
		'#!/bin/sh'*)
			printf '%s\n' "${changed_file}" \
			    >> "${tmp_dir}/changed-shell-files"
			;;
	esac
done < "${tmp_dir}/changed-files"

LC_ALL=C sort -u "${tmp_dir}/changed-shell-files" \
    > "${tmp_dir}/shell-files"
while IFS= read -r script; do
	shellcheck -s sh "${script}"
done < "${tmp_dir}/shell-files"

for baseline in \
    .github/ci/package-baseline.txt \
    .github/ci/sweep-baseline.txt
do
	if ! git cat-file -e "${base}:${baseline}" 2>/dev/null; then
		echo ">>> Bootstrapping new source-gate baseline: ${baseline}"
		continue
	fi
	[ -n "$(git rev-parse --verify "${head}:${baseline}" 2>/dev/null)" ] || {
		echo ">>> Source-gate baseline must not be deleted: ${baseline}" >&2
		exit 1
	}

	git show "${base}:${baseline}" |
	    sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' |
	    LC_ALL=C sort -u > "${tmp_dir}/baseline-old"
	git show "${head}:${baseline}" |
	    sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' |
	    LC_ALL=C sort -u > "${tmp_dir}/baseline-new"
	comm -13 "${tmp_dir}/baseline-old" "${tmp_dir}/baseline-new" \
	    > "${tmp_dir}/baseline-added"
	if [ -s "${tmp_dir}/baseline-added" ]; then
		echo ">>> Source-gate baselines cannot gain exceptions: ${baseline}" >&2
		sed 's/^/  /' "${tmp_dir}/baseline-added" >&2
		exit 1
	fi
done

if [ "${CI_SKIP_SELF_TESTS-}" != 1 ]; then
	Scripts/ci-self-tests.sh
fi

cleanup
trap - EXIT HUP INT TERM
