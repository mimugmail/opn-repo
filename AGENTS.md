# Repository guidance for coding agents

This file applies to the full repository. Read `CONTRIBUTING.md` and the
applicable issue before changing code. Human contributors and automation use
the same package, review, and disclosure requirements; tool-specific
instructions must not conflict with or weaken them.

## Repository model

- The Git tree contains eight package roots. The published community catalog is
  separate, larger, and not fully source-backed here.
- Treat OPNsense/FreeBSD package ABI and package ownership as compatibility
  constraints. Do not imply that source build success validates every catalog
  package or production service behavior.
- Preserve existing licenses and copyright notices. The root `LICENSE` and
  inherited file/package licenses are not interchangeable; do not relicense or
  overwrite third-party terms.
- Do not add or modify precompiled `.pkg` files without a maintainer-approved
  provenance entry in `.github/ci/binary-exceptions.txt`.

## Editing and generated files

- Follow `.editorconfig` and `.gitattributes`; use LF, preserve final newlines,
  and retain executable modes on scripts with shebangs.
- Keep package files under their category/package root and preserve the
  established `src/etc`, `src/opnsense`, `Makefile`, and `pkg-descr` layout.
- Do not hand-edit generated files in package `work/` directories, README
  temporary files, or the existing legacy package archive.
- Keep generated/vendor theme assets unchanged unless the change includes its
  source, provenance, and rebuild evidence.
- Avoid unrelated repository-wide formatting. Remove baseline debt rather than
  adding exceptions.

## Required checks

Run host checks on the committed base/head range:

```sh
base=$(git merge-base origin/main HEAD)
Scripts/ci-host-checks.sh --base "${base}" --head HEAD
actionlint -no-color .github/workflows/*.yml
```

For affected package source, select the exact roots and run the disposable
OPNsense VM wrapper described in `CONTRIBUTING.md`. A package change is not
complete until the stable **OPNsense VM/package checks** job passes at the
latest commit and builds, validates, and dry-runs every changed package.

Do not use `CI_PACKAGES=__NONE__`, a catalog audit, or a prior commit's green run
as package evidence. A changed package cannot use the unchanged-package build
exception. Run real install, upgrade, uninstall, rollback, migration, and
service evidence only in a disposable VM and report what was not tested.

## Safety and review

- Never commit credentials, private addresses, tokens, certificates, private
  logs, or live firewall configuration.
- Use `SECURITY.md` for sensitive findings instead of public issues.
- Do not install or uninstall production services, reboot a real firewall, or
  run package scripts outside a disposable test environment.
- Do not weaken Actions permissions, replace commit pins with mutable tags,
  expand source-gate baselines, bypass a red check, or claim CI is maintainer
  approval.
- Disclose AI/automated tools used and summarize runtime limitations in the PR.
