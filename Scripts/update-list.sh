#!/bin/sh

# Copyright (c) 2019 Franco Fichtner <franco@opnsense.org>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

set -e

SCRIPTSDIR=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
PLUGINSDIR=$(CDPATH='' cd -- "${SCRIPTSDIR}/.." && pwd)
MAKE=${MAKE:-make}
START_MARKER='<!-- package-list:start -->'
END_MARKER='<!-- package-list:end -->'

cd "${PLUGINSDIR}"

start_count=$(grep -c "^${START_MARKER}$" README.md || true)
end_count=$(grep -c "^${END_MARKER}$" README.md || true)
if [ "${start_count}" -ne 1 ] || [ "${end_count}" -ne 1 ]; then
	echo ">>> README.md needs one package-list marker pair." >&2
	exit 1
fi

list_file=$(mktemp "${TMPDIR:-/tmp}/opn-readme-list.XXXXXX")
output_file=$(mktemp "${TMPDIR:-/tmp}/opn-readme.XXXXXX")
cleanup()
{
	rm -f "${list_file}" "${output_file}"
}
trap cleanup EXIT HUP INT TERM

"${MAKE}" list 2> /dev/null > "${list_file}"

awk -v list_file="${list_file}" '
/^<!-- package-list:start -->$/ {
	print
	print "```text"
	while ((getline line < list_file) > 0) {
		print line
	}
	close(list_file)
	print "```"
	in_list = 1
	next
}
in_list && /^<!-- package-list:end -->$/ {
	in_list = 0
	print
	next
}
!in_list {
	print
}
' README.md > "${output_file}"

mv "${output_file}" README.md
