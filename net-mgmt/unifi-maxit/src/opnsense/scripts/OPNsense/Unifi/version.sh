#!/bin/sh

# Detect installed FreeBSD UniFi package version
ver=$(/usr/local/sbin/pkg query '%v' -g 'unifi[0-9]*' 2>/dev/null | head -n 1 | sed -E 's/[_,].*//')

if [ -z "$ver" ]; then
    ver=$(/usr/local/sbin/pkg query '%v' unifi 2>/dev/null | head -n 1 | sed -E 's/[_,].*//')
fi

# Fallback to local running daemon status endpoint if package query returned nothing
if [ -z "$ver" ]; then
    ver=$(/usr/local/bin/curl -sk -m 1 https://127.0.0.1:8443/status 2>/dev/null | sed -n 's/.*"server_version":"\([^"]*\)".*/\1/p')
fi

# Fallback to reading disk package.json if present
if [ -z "$ver" ] && [ -f /usr/local/share/java/unifi/webapps/ROOT/app-unifi/package.json ]; then
    ver=$(sed -n 's/.*"version": *"\{0,1\}\([^",]*\)"\{0,1\}.*/\1/p' /usr/local/share/java/unifi/webapps/ROOT/app-unifi/package.json 2>/dev/null | head -n 1)
fi

echo "${ver:-unknown}"
