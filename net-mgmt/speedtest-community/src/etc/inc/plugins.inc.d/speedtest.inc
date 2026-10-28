<?php

/*
 * Copyright (C) 2026 Blip9575
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

function speedtest_configure()
{
    return [
        'newwanip' => ['speedtest_configure_newwanip:2'],
    ];
}

/**
 * The shaper rules created for the speedtest exclude the interface address;
 * follow a change of that address (e.g. a PPPoE reconnect), otherwise the
 * speedtest is shaped and measures the pipe instead of the line.
 */
function speedtest_configure_newwanip($verbose = false, $interfaces = null)
{
    global $config;

    if (!plugins_argument_map($interfaces)) {
        return;
    }

    $shaper = $config['OPNsense']['speedtest']['shaper'] ?? [];
    if (empty($shaper['address'])) {
        /* no exclusion recorded yet, nothing to follow */
        return;
    }
    if (is_array($interfaces) && !in_array($shaper['interface'] ?? 'wan', $interfaces)) {
        return;
    }

    service_log('Updating speedtest shaper exclusion...', $verbose);
    (new \OPNsense\Core\Backend())->configdRun('speedtest syncshaper');
    service_log("done.\n", $verbose);
}
