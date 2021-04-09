# opn-repo
OPNsense repo by mimugmail


Here you'll find source of a couple of plugins but it's mainly just for tracking bugs or new feature requests.

You'll find everything else here:
https://www.routerperformance.net/opnsense-repo/

Install this repo:

```
fetch -o /usr/local/etc/pkg/repos/mimugmail.conf https://www.routerperformance.net/mimugmail.conf
pkg update
```

Find out what is available in the (installed) repo:
```
pkg search -g -r mimugmail \*
```

Remove this repo:
```
rm /usr/local/etc/pkg/repos/mimugmail.conf
```
(removing the repo will not remove previously installed packages from the repo)

Find out what you have installed from this repo:
```
pkg query -a '%R %n-%v' | grep mimugmail
```
