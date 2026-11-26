#!/bin/sh

set -eu

SCRIPTSDIR=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
PLUGINSDIR=$(CDPATH='' cd -- "${SCRIPTSDIR}/.." && pwd)
TMPDIR_BASE=$(mktemp -d "${TMPDIR:-/tmp}/opn-ci-tests.XXXXXX")

cleanup()
{
	[ -d "${TMPDIR_BASE}" ] || return 0
	rm -rf "${TMPDIR_BASE}"
}
trap cleanup EXIT HUP INT TERM

fail()
{
	echo ">>> $*" >&2
	exit 1
}

assert_equal()
{
	expected=$1
	actual=$2
	message=$3

	[ "${actual}" = "${expected}" ] || {
		echo ">>> ${message}" >&2
		echo "expected: ${expected}" >&2
		echo "actual:   ${actual}" >&2
		exit 1
	}
}

selection_repo="${TMPDIR_BASE}/selection"
git init -q -b main "${selection_repo}"
git -C "${selection_repo}" config user.name "CI self-test"
git -C "${selection_repo}" config user.email "ci@example.invalid"
mkdir -p \
    "${selection_repo}/Scripts" \
    "${selection_repo}/dns/a/src" \
    "${selection_repo}/net/b/src"
cp "${PLUGINSDIR}/Scripts/ci-packages.sh" "${selection_repo}/Scripts/"
chmod 755 "${selection_repo}/Scripts/ci-packages.sh"
printf 'PLUGIN_NAME=a\n' > "${selection_repo}/dns/a/Makefile"
printf 'PLUGIN_NAME=b\n' > "${selection_repo}/net/b/Makefile"
printf 'base\n' > "${selection_repo}/dns/a/src/moved"
git -C "${selection_repo}" add .
git -C "${selection_repo}" commit -q -m base
base=$(git -C "${selection_repo}" rev-parse HEAD)
full=$(printf 'dns/a\nnet/b')

git -C "${selection_repo}" switch -q -c feature-merge "${base}"
printf 'feature\n' > "${selection_repo}/dns/a/src/feature"
git -C "${selection_repo}" add .
git -C "${selection_repo}" commit -q -m feature
feature=$(git -C "${selection_repo}" rev-parse HEAD)

git -C "${selection_repo}" switch -q main
printf 'base branch\n' > "${selection_repo}/net/b/src/base-only"
git -C "${selection_repo}" add .
git -C "${selection_repo}" commit -q -m "move base"
new_base=$(git -C "${selection_repo}" rev-parse HEAD)

actual=$(
	"${selection_repo}/Scripts/ci-packages.sh" list \
	    --scope changed --base "${new_base}" --head "${feature}"
)
assert_equal "dns/a" "${actual}" \
    "changed-package selection did not use the PR merge base"

git -C "${selection_repo}" switch -q -c feature-rename "${base}"
mkdir -p "${selection_repo}/net/b/src"
git -C "${selection_repo}" mv \
    dns/a/src/moved net/b/src/moved
git -C "${selection_repo}" commit -q -m rename
renamed=$(git -C "${selection_repo}" rev-parse HEAD)
actual=$(
	"${selection_repo}/Scripts/ci-packages.sh" list \
	    --scope changed --base "${base}" --head "${renamed}"
)
assert_equal "${full}" "${actual}" \
    "renamed paths did not select their old and new package roots"

for gate_path in \
    .github/workflows/opnsense.yml \
    .github/ci/package-baseline.txt
do
	git -C "${selection_repo}" switch -q main
	branch="gate-$(
		printf '%s\n' "${gate_path}" | tr '/.' '--'
	)"
	git -C "${selection_repo}" switch -q -c "${branch}" "${base}"
	mkdir -p "${selection_repo}/$(dirname "${gate_path}")"
	printf 'gate\n' > "${selection_repo}/${gate_path}"
	git -C "${selection_repo}" add .
	git -C "${selection_repo}" commit -q -m gate
	gate_head=$(git -C "${selection_repo}" rev-parse HEAD)
	actual=$(
		"${selection_repo}/Scripts/ci-packages.sh" list \
		    --scope changed --base "${base}" --head "${gate_head}"
	)
	assert_equal "${full}" "${actual}" \
	    "gate change did not select every package: ${gate_path}"
done

host_repo="${TMPDIR_BASE}/host"
git clone -q "${PLUGINSDIR}" "${host_repo}"
git -C "${host_repo}" config user.name "CI self-test"
git -C "${host_repo}" config user.email "ci@example.invalid"
cp "${PLUGINSDIR}/Scripts/ci-host-checks.sh" "${host_repo}/Scripts/"
cp "${PLUGINSDIR}/Scripts/ci-self-tests.sh" "${host_repo}/Scripts/"
chmod 755 \
    "${host_repo}/Scripts/ci-host-checks.sh" \
    "${host_repo}/Scripts/ci-self-tests.sh"
git -C "${host_repo}" add Scripts/ci-host-checks.sh \
    Scripts/ci-self-tests.sh
if ! git -C "${host_repo}" diff --cached --quiet; then
	git -C "${host_repo}" commit -q -m "use working CI checks"
fi
range_base=$(git -C "${host_repo}" rev-parse HEAD)

CI_SKIP_SELF_TESTS=1 \
    "${host_repo}/Scripts/ci-host-checks.sh" \
    --base "${range_base}" --head "${range_base}"

printf 'trailing whitespace \n' > "${host_repo}/range-fixture.txt"
git -C "${host_repo}" add range-fixture.txt
git -C "${host_repo}" commit -q -m "bad whitespace"
bad_range=$(git -C "${host_repo}" rev-parse HEAD)
if CI_SKIP_SELF_TESTS=1 \
    "${host_repo}/Scripts/ci-host-checks.sh" \
    --base "${range_base}" --head "${bad_range}" \
    >/dev/null 2>&1
then
	fail "committed-range whitespace validation unexpectedly passed"
fi

printf 'clean\n' > "${host_repo}/range-fixture.txt"
git -C "${host_repo}" add range-fixture.txt
git -C "${host_repo}" commit -q -m "clean whitespace"
good_range=$(git -C "${host_repo}" rev-parse HEAD)
CI_SKIP_SELF_TESTS=1 \
    "${host_repo}/Scripts/ci-host-checks.sh" \
    --base "${range_base}" --head "${good_range}"

mkdir -p "${host_repo}/Scripts/zzz-ci-test"
printf 'if\n' > "${host_repo}/Scripts/zzz-ci-test/invalid.sh"
git -C "${host_repo}" add Scripts/zzz-ci-test/invalid.sh
git -C "${host_repo}" commit -q -m "bad shell"
bad_shell=$(git -C "${host_repo}" rev-parse HEAD)
if CI_SKIP_SELF_TESTS=1 \
    "${host_repo}/Scripts/ci-host-checks.sh" \
    --base "${good_range}" --head "${bad_shell}" \
    >/dev/null 2>&1
then
	fail "shell validation did not check every pathname"
fi

git -C "${host_repo}" rm -q Scripts/zzz-ci-test/invalid.sh
git -C "${host_repo}" commit -q -m "remove bad shell"
clean_shell=$(git -C "${host_repo}" rev-parse HEAD)
CI_SKIP_SELF_TESTS=1 \
    "${host_repo}/Scripts/ci-host-checks.sh" \
    --base "${bad_shell}" --head "${clean_shell}"

mkdir -p "${host_repo}/Scripts/zzz-ci-test"
printf '#!/bin/sh\nexit 0\n' \
    > "${host_repo}/Scripts/zzz-ci-test/nonexec.sh"
git -C "${host_repo}" add Scripts/zzz-ci-test/nonexec.sh
git -C "${host_repo}" commit -q -m "add non-executable script"
nonexec_script=$(git -C "${host_repo}" rev-parse HEAD)
if CI_SKIP_SELF_TESTS=1 \
    "${host_repo}/Scripts/ci-host-checks.sh" \
    --base "${clean_shell}" --head "${nonexec_script}" \
    >/dev/null 2>&1
then
	fail "shell executable-mode validation unexpectedly passed"
fi

chmod 755 "${host_repo}/Scripts/zzz-ci-test/nonexec.sh"
git -C "${host_repo}" add Scripts/zzz-ci-test/nonexec.sh
git -C "${host_repo}" commit -q -m "fix script mode"
exec_script=$(git -C "${host_repo}" rev-parse HEAD)
CI_SKIP_SELF_TESTS=1 \
    "${host_repo}/Scripts/ci-host-checks.sh" \
    --base "${nonexec_script}" --head "${exec_script}"

printf 'not-a-package\n' > "${host_repo}/new-artifact.pkg"
git -C "${host_repo}" add -f new-artifact.pkg
git -C "${host_repo}" commit -q -m "add binary package"
binary_package=$(git -C "${host_repo}" rev-parse HEAD)
if CI_SKIP_SELF_TESTS=1 \
    "${host_repo}/Scripts/ci-host-checks.sh" \
    --base "${exec_script}" --head "${binary_package}" \
    >/dev/null 2>&1
then
	fail "precompiled package unexpectedly passed without an exception"
fi

printf 'new-artifact.pkg\n' \
    >> "${host_repo}/.github/ci/binary-exceptions.txt"
git -C "${host_repo}" add .github/ci/binary-exceptions.txt
git -C "${host_repo}" commit -q -m "approve binary exception"
approved_binary=$(git -C "${host_repo}" rev-parse HEAD)
CI_SKIP_SELF_TESTS=1 \
    "${host_repo}/Scripts/ci-host-checks.sh" \
    --base "${exec_script}" --head "${approved_binary}"

printf 'net-mgmt/new-exception\n' \
    >> "${host_repo}/.github/ci/package-baseline.txt"
git -C "${host_repo}" add .github/ci/package-baseline.txt
git -C "${host_repo}" commit -q -m "grow package baseline"
grown_baseline=$(git -C "${host_repo}" rev-parse HEAD)
if CI_SKIP_SELF_TESTS=1 \
    "${host_repo}/Scripts/ci-host-checks.sh" \
    --base "${approved_binary}" --head "${grown_baseline}" \
    >/dev/null 2>&1
then
	fail "source-gate baseline unexpectedly accepted a new exception"
fi

echo ">>> CI selection and committed-range self-tests passed."
