#!/bin/sh

set -eu

SCRIPTSDIR=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
PLUGINSDIR=$(CDPATH='' cd -- "${SCRIPTSDIR}/.." && pwd)
MAKE=${MAKE:-make}

usage()
{
	echo "Usage:" >&2
	echo "  $0 list --scope full" >&2
	echo "  $0 list --scope changed --base <commit> [--head <commit>]" >&2
	echo "  $0 run" >&2
	exit 2
}

package_roots()
{
	(
		cd "${PLUGINSDIR}"
		find . \
		    \( -path './.git' -o -path '*/work' \) -prune -o \
		    -type f -name Makefile -print |
		    sed 's|^\./||' |
		    awk -F/ 'NF == 3 { print $1 "/" $2 }' |
		    LC_ALL=C sort -u
	)
}

changed_packages()
{
	base=$1
	head=$2

	git -C "${PLUGINSDIR}" rev-parse --verify "${base}^{commit}" >/dev/null
	git -C "${PLUGINSDIR}" rev-parse --verify "${head}^{commit}" >/dev/null

	changed=$(
		git -C "${PLUGINSDIR}" diff --name-only "${base}" "${head}" --
	)

	all=
	for path in ${changed}; do
		case "${path}" in
		Makefile|Mk/*|Scripts/*|Templates/*|Keywords/*|ruleset.xml)
			all=yes
			break
			;;
		esac
	done

	if [ "${all}" = yes ]; then
		package_roots
		return
	fi

	for path in ${changed}; do
		package=$(printf '%s\n' "${path}" |
		    awk -F/ 'NF >= 2 { print $1 "/" $2 }')
		if [ -n "${package}" ] &&
		    [ -f "${PLUGINSDIR}/${package}/Makefile" ]; then
			printf '%s\n' "${package}"
		fi
	done | LC_ALL=C sort -u
}

select_packages()
{
	scope=
	base=
	head=HEAD

	while [ "$#" -gt 0 ]; do
		case "$1" in
		--scope)
			[ "$#" -ge 2 ] || usage
			scope=$2
			shift 2
			;;
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

	case "${scope}" in
	full)
		package_roots
		;;
	changed)
		[ -n "${base}" ] || usage
		changed_packages "${base}" "${head}"
		;;
	*)
		usage
		;;
	esac
}

cleanup_test_fixture()
{
	rm -f "${fixture_dir}/bin/phpunit" \
	    "${fixture_dir}/tests/.phpunit.result.cache"
	rmdir "${fixture_dir}/bin" "${fixture_dir}/tests" "${fixture_dir}"
}

verify_test_failure_propagates()
{
	package=$1
	fixture_dir=$(mktemp -d "${TMPDIR:-/tmp}/opn-repo-ci.XXXXXX")
	trap cleanup_test_fixture EXIT HUP INT TERM

	mkdir -p "${fixture_dir}/bin" "${fixture_dir}/tests"
	cat > "${fixture_dir}/bin/phpunit" <<-'EOF'
#!/bin/sh
touch .phpunit.result.cache
exit 23
EOF
	chmod 755 "${fixture_dir}/bin/phpunit"

	if PATH="${fixture_dir}/bin:${PATH}" \
	    "${MAKE}" -C "${PLUGINSDIR}/${package}" \
	    TESTDIR="${fixture_dir}/tests" test; then
		echo ">>> The test target unexpectedly hid a phpunit failure." >&2
		exit 1
	fi

	if [ -e "${fixture_dir}/tests/.phpunit.result.cache" ]; then
		echo ">>> The test target did not remove its phpunit cache." >&2
		exit 1
	fi

	cleanup_test_fixture
	trap - EXIT HUP INT TERM
}

run_packages()
{
	packages=${CI_PACKAGES-}

	[ -n "${packages}" ] || {
		echo ">>> CI_PACKAGES is not set." >&2
		exit 2
	}

	verified_roots=$(package_roots)
	first_package=$(printf '%s\n' "${verified_roots}" | sed -n '1p')
	[ -n "${first_package}" ] || {
		echo ">>> No package Makefiles found." >&2
		exit 1
	}
	verify_test_failure_propagates "${first_package}"

	if [ "${packages}" = __NONE__ ]; then
		echo ">>> No tracked package roots need source checks for this change."
		exit 0
	fi

	for package in ${packages}; do
		case "${package}" in
		[a-z0-9]*/*)
			;;
		*)
			echo ">>> Invalid package root: ${package}" >&2
			exit 2
			;;
		esac
		[ -f "${PLUGINSDIR}/${package}/Makefile" ] || {
			echo ">>> Package root does not exist: ${package}" >&2
			exit 2
		}
	done

	echo ">>> Checking package metadata, lint, tests, and style:"
	for package in ${packages}; do
		printf '    %s\n' "${package}"
	done
	for package in ${packages}; do
		echo ">>> Entering ${package}"
		"${MAKE}" -C "${PLUGINSDIR}/${package}" check
		"${MAKE}" -C "${PLUGINSDIR}/${package}" lint
		"${MAKE}" -C "${PLUGINSDIR}/${package}" test
		"${MAKE}" -C "${PLUGINSDIR}/${package}" style
		"${MAKE}" -C "${PLUGINSDIR}/${package}" sweep
	done

	echo ">>> Requiring sweep and style to leave tracked files unchanged."
	git -C "${PLUGINSDIR}" diff --exit-code

	echo ">>> Building and validating package archives:"
	for package in ${packages}; do
		echo ">>> Packaging ${package}"
		"${MAKE}" -C "${PLUGINSDIR}/${package}" package

		artifact=
		for candidate in "${PLUGINSDIR}/${package}"/work/pkg/*.pkg; do
			[ -f "${candidate}" ] || continue
			[ -z "${artifact}" ] || {
				echo ">>> Multiple package artifacts in ${package}/work/pkg." >&2
				exit 1
			}
			artifact=${candidate}
		done
		[ -n "${artifact}" ] || {
			echo ">>> Package target produced no archive for ${package}." >&2
			exit 1
		}

		/usr/local/sbin/pkg info -F "${artifact}" >/dev/null
		/usr/local/sbin/pkg add -n "${artifact}"
		echo ">>> Package archive verified: ${artifact}"
	done

	git -C "${PLUGINSDIR}" diff --exit-code
}

[ "$#" -gt 0 ] || usage
command=$1
shift

case "${command}" in
list)
	select_packages "$@"
	;;
run)
	[ "$#" -eq 0 ] || usage
	run_packages
	;;
*)
	usage
	;;
esac
