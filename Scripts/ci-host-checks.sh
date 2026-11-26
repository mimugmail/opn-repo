#!/bin/sh

set -eu

SCRIPTSDIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
PLUGINSDIR=$(CDPATH= cd -- "${SCRIPTSDIR}/.." && pwd)

cd "${PLUGINSDIR}"

find . \
    \( -path './.git' -o -path '*/work' \) -prune -o \
    -type f -name '*.sh' -exec sh -n {} +

find .github -type f \( -name '*.yml' -o -name '*.yaml' \) \
    -exec ruby -e \
    'require "yaml"; ARGV.each { |path| YAML.load_file(path) }' \
    {} +

git diff --check
