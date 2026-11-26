# Contributing

This is an unsupported community repository. The tracked Git tree covers eight
package roots; it does not cover the full published binary repository, its
catalog, or packages such as many AdGuard, Caddy, Grafana, Elasticsearch,
InfluxDB, and service-binary builds. Published packages receive occasional
testing rather than an upstream OPNsense support guarantee.

Report a reproducible problem first for a new plugin or substantial feature.
Keep submissions small and reviewable, explain the problem and solution, and
target the latest applicable branch. Source must preserve the BSD-2-Clause
license. Service binaries belong in the FreeBSD ports tree rather than as
precompiled assets here.

For this repository, no new precompiled package or binary may be committed
without source/provenance, a reproducible build, and an explicit maintainer
exception. The existing `os-adguardhome-maxit-1.19.pkg` is a legacy artifact
without matching source in this tree and remains a verification gap; its presence
is not precedent for new submissions.

## Report or submit

Include the affected package and installed version, OPNsense version, FreeBSD
ABI (`pkg config abi`), repository configuration, minimal reproduction, relevant
logs, and dependency conflicts. State whether evidence came from a clean install,
an upgrade, or both, and identify the prior package version for upgrades.

Pull requests should include compatibility analysis, `make` results, package
build evidence, and any install/uninstall or rollback limitations. Disclose any
AI or automated tools and models used; disclosure is not a ban or an approval
signal.

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
`Scripts`, `Templates`, or root Make changes. Pushes to `main` and manual runs
check all packages.

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

The source job builds real `.pkg` archives, verifies their metadata with `pkg
info`, and uses `pkg add -n` as an installability dry run. It does not install or
uninstall production services in the appliance: package scripts may restart
OPNsense services or start external daemons, so that smoke stage is intentionally
left to contributor-provided clean-install and upgrade evidence rather than
being masked as an always-green test.

## Published repository checks

The separate scheduled/manual catalog workflow is not a pull-request gate and
must not be used as evidence that an eight-source-package change validates the
binary corpus.

It installs the published full-repository configuration, refreshes metadata,
records the OPNsense version and package ABI, verifies the maintained `os-*`
manifest, and dry-runs dependency resolution for each expected plugin. Current
coverage does not prove package execution, clean installation, upgrades,
uninstalls, service health, or every dependency package in the 159-entry
catalog.

The repository's public page says `mimugmail-single.conf` is AdGuard-only, but
the current FreeBSD:15:amd64 single catalog contains six `os-*` plugins. The
separate policy job is intentionally expected-red on this known
[#290](https://github.com/mimugmail/opn-repo/issues/290) discrepancy; it is not
weakened by accepting the extra entries and is not a required pull-request check.

## Approval

Passing checks supplies test evidence only. Maintainer review and any branch
protection or ruleset settings remain administrative decisions outside workflow
code.
