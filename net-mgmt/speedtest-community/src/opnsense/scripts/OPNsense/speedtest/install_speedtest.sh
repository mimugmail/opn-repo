#!/bin/sh
# Copyright (C) 2021 Miha Kralj
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
# OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

PYTHON_PKG_NAME=$(pkg info -x 'python3*' | grep 'python3' | sed -n 's/^python\([0-9]*\).*/py\1-speedtest-cli/p')
OOKLA_URL=$(curl -s "https://www.speedtest.net/apps/cli" | xmllint --html --xpath "string(//*[@id='freebsd']/pre/code[7]/text())" - 2>/dev/null | awk -F'"' '{print $2}')

if [ $1 = 'http' ] 
then 
  pkg delete -y speedtest
  pkg install -f -y ${PYTHON_PKG_NAME}
elif [ $1 = 'socket' ] 
then 
  pkg delete -y ${PYTHON_PKG_NAME}
  pkg install -y libidn2
  pkg add -f ${OOKLA_URL}
elif [ $1 = 'delete' ]
then
  pkg delete -y speedtest
  pkg delete -y ${PYTHON_PKG_NAME}
fi

