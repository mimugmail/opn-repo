## Problem

What breaks, and for whom? Link the related issue.

## Solution

Describe the smallest reviewable change and explain package/service compatibility.

## Affected package

- Package name and version:
- OPNsense / FreeBSD version and package ABI:
- Dependency or package-repository compatibility:
- Added third-party source, asset, or binary license/provenance:

## Evidence

- Reproduction before the change:
- Clean-install result, or "not tested":
- Upgrade result from the prior package, or "not tested":
- Uninstall/rollback result, or "not tested":
- `make lint`, `make test`, `make style`, `make sweep`, and `make package`
  results:
- Relevant logs and screenshots:
- Full-repository catalog result, if applicable:

## Submission gate

- [ ] The latest commit passed **OPNsense VM/package checks** (link below).
- [ ] The run selected every affected tracked package and did not use
      `CI_PACKAGES=__NONE__` for a package-source change.
- [ ] Every changed package built a real archive, passed metadata validation,
      and completed the local installability dry-run.
- [ ] No package/shell/sweep baseline was added or expanded to hide this change.
- [ ] No shell/sweep lint exception grew; each changed shell script passes
      ShellCheck and retains its executable mode.
- [ ] No precompiled `.pkg` was added or changed without a documented
      maintainer exception and matching provenance entry.

Successful gate run:

## Tooling disclosure

List AI or automated tools and models used to prepare the change, or write
"none". This is disclosure, not an approval signal.

## Maintainer note

Passing CI is not automated maintainer approval. Include any required rollback or
exception details.
