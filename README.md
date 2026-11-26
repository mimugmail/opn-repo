# opn-repo

This is an unsupported OPNsense community repository maintained by
[mimugmail](https://github.com/mimugmail). The Git tree contains source for a
small tracked package set; the published binary repository is larger and is
documented at <https://www.routerperformance.net/opnsense-repo/>.

## Tracked package source

<!-- package-list:start -->
```text
dns/nextdns-community -- NextDNS CLI
dns/unboundcustom-maxit -- Unbound Custom Options
misc/theme-dracula-community -- Dracula theme - dark mode only
misc/theme-solarized-community -- Solarized theme - tracking OS dark mode
net-mgmt/ipcheck-community -- Verification of public IP address
net-mgmt/speedtest-community -- Speedtest
net-mgmt/unifi-maxit -- Unifi Controller
sysutils/auto-recovery -- A configuration rollback feature for OPNsense
```
<!-- package-list:end -->

Source coverage does not imply that every package in the published catalog is
represented here or has the same support, provenance, or test evidence.

## Install the published repository

```sh
fetch -o /usr/local/etc/pkg/repos/mimugmail.conf \
    https://www.routerperformance.net/mimugmail.conf
pkg update
```

List available packages:

```sh
pkg search -g -r mimugmail \*
```

Remove the repository configuration:

```sh
rm /usr/local/etc/pkg/repos/mimugmail.conf
```

Removing the repository configuration does not uninstall packages that came
from it. List currently installed packages from this repository with:

```sh
pkg query -a '%R %n-%v' | grep mimugmail
```

## Reporting, contributing, and support

Read [CONTRIBUTING.md](CONTRIBUTING.md) before proposing package changes. Use
the issue templates for reproducible bugs and package proposals, and include the
OPNsense version, FreeBSD package ABI, exact package version, and install or
upgrade context.

Report sensitive vulnerabilities using the process in
[SECURITY.md](SECURITY.md). Automation and coding agents must also follow
[AGENTS.md](AGENTS.md).
