# Contributing

This is an unsupported community repository. The tracked Git tree covers eight
package roots; it does not cover the full published binary repository, its
catalog, or packages such as many AdGuard, Caddy, Grafana, Elasticsearch,
InfluxDB, and service-binary builds. Published packages receive occasional
testing rather than an upstream OPNsense support guarantee.

Report a reproducible problem first for a new plugin or substantial feature.
Keep submissions small and reviewable, explain the problem and solution, and
target the latest applicable branch. Preserve the copyright and license notices
already attached to a file and document the license/source/provenance of new
third-party code or assets. The repository `LICENSE` contains project-specific
terms, while many inherited files and package manifests use BSD-2-Clause; do
not replace, relicense, or assume those terms are identical without a maintainer
decision. Service binaries belong in the FreeBSD ports tree rather than as
precompiled assets here.

For this repository, no new or modified precompiled package may be committed
without source/provenance, a reproducible build or documented impossibility, a
linked maintainer decision, and an entry in `.github/ci/binary-exceptions.txt`.
The existing 8.1 MB `os-adguardhome-maxit-1.19.pkg` is a legacy artifact
without matching source in this tree and remains a verification gap; its
presence is not precedent for new submissions or an automatic exception.

## Report or submit

Include the affected package and installed version, OPNsense version, FreeBSD
ABI (`pkg config abi`), repository configuration, minimal reproduction, relevant
logs, and dependency conflicts. State whether evidence came from a clean install,
an upgrade, or both, and identify the prior package version for upgrades.

Pull requests should include compatibility analysis, `make` results, package
build evidence, and any install/uninstall or rollback limitations. Disclose any
AI or automated tools and models used; disclosure is not a ban or an approval
signal.

Report sensitive security problems through [SECURITY.md](SECURITY.md) rather
than a public bug issue. Redact credentials, private addresses, tokens, logs,
and exploit details before sharing.

## Repository conventions

`.editorconfig`, `.gitattributes`, and `.gitignore` define the basic file,
line-ending, binary-asset, and generated-file conventions. Keep Makefiles and
shell indentation consistent with the surrounding file, preserve executable
bits on directly invoked scripts, and do not commit `work/`, `.phpunit` cache,
temporary README files, or package archives. Run `make sync` to refresh the
README package list when package roots change; the license target is
intentionally separate and must not be used for routine synchronization.

Humans and automation should follow the same review surface: `CONTRIBUTING.md`
is the policy source, [AGENTS.md](AGENTS.md) adds repository-specific guidance
for coding agents, and `CLAUDE.md` plus
`.github/copilot-instructions.md` point their tools to that shared guidance.
Do not create tool-specific rules that contradict these files.

## Submission gate

A commit is not merge-ready merely because the source was reviewed. At the
latest PR head, every changed tracked package must be selected by and pass the
stable **OPNsense VM/package checks** job before merge. For a package change,
that means the package's core checks and tests run, a real `.pkg` archive is
built and validated with `pkg info`, and the local package installability
dry-run completes. A changed package cannot use the unchanged-package build
exception, even if its path is present in
`.github/ci/package-baseline.txt`.

Failures must be fixed by a new commit followed by a fresh successful run.
Documentation-only changes may report `CI_PACKAGES=__NONE__`, but that is not
package evidence. Catalog checks are independent evidence and are not a
substitute for this source gate.

The host portion of the submission gate validates shell and workflow syntax,
ShellChecks all shell helpers while allowing documented failures only in
unchanged baseline files, strictly checks changed shell scripts with shell
shebangs, preserves executable modes, rejects unapproved `.pkg` additions or
modifications, runs whitespace/range checks and focused self-tests, and prevents
established package/shell/sweep baselines from gaining new exceptions. The
source/package portion uses the disposable OPNsense VM. Do not bypass a red
result by editing a baseline; remove an exception only after the underlying
package is corrected.

## Source checks

The workflow pins OPNsense 26.7 x86_64, runs in a real `opnsense-vm`, and checks
out `opnsense/core` stable/26.7 at
`4092e306ab6cfa9748875053fbb41c4c7cd5af2d` as the adjacent `../core` checkout.
It uses the authoritative core Make fragments for `check`, `lint`, `style`,
`sweep`, and `package`.

Core's style and sweep targets can be informational or mutate files, so CI
separates that behavior from authoritative lint results. The initial clean-tree
baseline contains 47 files that current core `sweep` would reformat; they are
recorded in `.github/ci/sweep-baseline.txt` to avoid an unrelated repository-wide
rewrite. The gate fails if sweep changes any file modified by the change or any
file outside that baseline, then restores the checked-in tree before packaging.
The baseline must be reduced, not expanded, during normal maintenance. Pull
requests check affected package roots, plus all packages for shared `Mk`,
`Scripts`, `Templates`, root Make changes, `.github/workflows/opnsense.yml`, or
`.github/ci` gate baselines. Pushes to `main` and manual runs check all
packages.

The initial ShellCheck debt is recorded in
`.github/ci/shellcheck-baseline.txt`. Unchanged entries may retain existing
findings, but changing one of those files requires it to pass ShellCheck. The
baseline is shrink-only after this proposal is merged.

The package-build baseline in `.github/ci/package-baseline.txt` is stricter than
the formatting baseline. An unchanged `net-mgmt/unifi-maxit` is currently
linted and dry-checked but not packaged because its tracked Makefile requires
`unifi6`, which is absent from the current OPNsense 26.7 full repository (the
catalog publishes `unifi9` and `unifi10`). A change inside that package cannot
use the exception and must resolve the dependency before its real package build
can pass. Do not use this manifest to avoid builds for newly changed packages.
Machine-enforced baseline checks reject new entries after the initial baseline
is established, so normal maintenance can only reduce them.

To run the same source checks on an OPNsense 26.7 VM, install:

```sh
pkg update -f
pkg upgrade -y php85
pkg install -y git libxml2 perl5 \
    php85-pear-PHP_CodeSniffer py313-pycodestyle
```

Then select all packages and run the guest wrapper:

```sh
CI_PACKAGES="$(Scripts/ci-packages.sh list --scope full | paste -sd' ' -)"
export CI_PACKAGES
export CI_CHANGED_FILES=__NONE__
Scripts/ci-opnsense.sh
```

For a pull request, pass a package list selected from the base and head commits:

```sh
CI_PACKAGES="$(
    Scripts/ci-packages.sh list --scope changed \
        --base "$(git merge-base origin/main HEAD)" \
        --head HEAD |
        paste -sd' ' -
)"
export CI_PACKAGES
CI_CHANGED_FILES="$(git diff --name-only "$(
    git merge-base origin/main HEAD)" HEAD | paste -sd' ' -)"
export CI_CHANGED_FILES
Scripts/ci-opnsense.sh
```

Run committed-range checks before the guest step:

```sh
base=$(git merge-base origin/main HEAD)
Scripts/ci-host-checks.sh --base "${base}" --head HEAD
```

Install ShellCheck for that host step and the same
`actionlint -no-color .github/workflows/*.yml` used by CI. Both tools must report
no errors. The OPNsense VM wrapper also runs the root `make list` target so
repository categorization and package metadata discovery remain valid as
dotfiles, packages, and legacy root artifacts are added.

The source job builds real `.pkg` archives, verifies their metadata with `pkg
info`, and uses `pkg install -n -y -l` as an installability dry run. `make
package` also installs missing `PLUGIN_DEPENDS`; their package install scripts
may execute and modify the system. Run the workflow only in the disposable
OPNsense VM. The built plugin itself is not installed or uninstalled: its
package scripts may restart OPNsense services or start external daemons, so that
smoke stage remains contributor-provided clean-install and upgrade evidence
rather than an always-green test.

## Published repository checks

The separate scheduled/manual catalog workflow is not a pull-request gate and
must not be used as evidence that an eight-source-package change validates the
binary corpus.

It installs the published full-repository configuration, refreshes metadata,
records the OPNsense version and package ABI, verifies the maintained `os-*`
manifest, fetches exactly one target plugin archive from `mimugmail`, and
dry-runs that local archive against the enabled repositories. Current coverage
does not prove package execution, clean installation, upgrades, uninstalls,
service health, or every dependency package in the 159-entry catalog. Missing
dependencies reported by this job are remeasured from the current package
catalog on every run rather than stored as a hard-coded failure baseline.

The corrected cross-repository probe currently finds two missing-dependency
chains: `os-kibana8-maxit` through `node24` to `nbytes`, and
`os-zeek-maxit` through `zeek` to `py313-zkg`. The fetched
`os-adguardhome-maxit` archive passes metadata validation, but its local
dry-run ends in a `pkg` child-process segmentation fault; that is tracked as a
separate catalog reproducibility failure, not counted as a missing dependency.

The repository's public page says `mimugmail-single.conf` is AdGuard-only, but
the current FreeBSD:15:amd64 single catalog contains six `os-*` plugins. The
separate policy job is intentionally expected-red on this known
[#290](https://github.com/mimugmail/opn-repo/issues/290) discrepancy; it is not
weakened by accepting the extra entries and is not a required pull-request check.

## Approval

Passing checks supplies test evidence only. Maintainer review and any branch
protection or ruleset settings remain administrative decisions outside workflow
code. For a merge-enforcing rollout, the maintainer/admin recommendation is to
protect `main` with required pull requests, at least one maintainer or code-owner
approval, dismissal of stale approvals, required conversation resolution, and
the stable **OPNsense VM/package checks** status at the latest commit. Restrict
force pushes, branch deletion, and ruleset bypasses; enable secret scanning and
push protection where available. The proposed `CODEOWNERS` file assigns
repository control paths to the maintainer, but review remains ineffective
until required by a repository rule. Keep catalog audit jobs non-required until
their external failures have a deliberate owner and response process.
