#!/usr/local/bin/php
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

/*
 * Set the traffic shaper pipes of an interface from the speedtest results.
 *
 *   shaper.php set     the best result of each day: the best of the last N days lowers a
 *                      pipe at once by the minimum change, the lowest of the last 2N days
 *                      raises it (see RAISE_* below); scaled by the thresholds (and the
 *                      DSL overhead of the upload's ACKs)
 *   shaper.php create  create pipes, queues and rules on the interface for the
 *                      directions that have none yet
 *   shaper.php sync    when the interface address changed (newwanip hook), update
 *                      the rules that exclude the previous address; set runs it too
 *   shaper.php mss     MSS clamping status of the interface
 *   shaper.php setmss  set the interface MSS to its MTU (clamping to MTU - 40)
 *   shaper.php rules   second step of create (run by create itself): a rule can
 *                      only refer to a queue that the process saw when it loaded
 *                      the model, so the rules are added by a fresh process
 *
 * Pipes are found through the shaper rules on the interface (in: download,
 * out: upload, a queue counts as its pipe), else by the names below.
 */

require_once('script/load_phalcon.php');
require_once('config.inc');
require_once('interfaces.inc');
require_once('util.inc');

use OPNsense\Core\Backend;
use OPNsense\Core\Config;
use OPNsense\Speedtest\Speedtest;
use OPNsense\TrafficShaper\TrafficShaper;

const CSV_FILE = '/usr/local/opnsense/scripts/OPNsense/speedtest/speedtest.csv';
// when a pipe was last lowered, per direction
const STATE_FILE = '/usr/local/opnsense/scripts/OPNsense/speedtest/shaper.json';
const LOCK_FILE = '/tmp/speedtest_shaper.lock';
// every update of the pipes (set), the last HISTORY_ROWS of them; filled from syslog when it is missing
const HISTORY_FILE = '/usr/local/opnsense/scripts/OPNsense/speedtest/shaper.csv';
const HISTORY_ROWS = 365;
const HISTORY_HEADER = ['time (UTC)', 'status', 'download before (Mbit/s)', 'download after (Mbit/s)', 'download',
    'upload before (Mbit/s)', 'upload after (Mbit/s)', 'upload', 'best download (Mbit/s)', 'best upload (Mbit/s)',
    'raise download (Mbit/s)', 'raise upload (Mbit/s)', 'basis', 'message'];
const SYSLOG_FILES = '/var/log/system/system_*.log';
// CoDel default target and interval (ms)
const CODEL_TARGET_MS = 5;
const CODEL_INTERVAL_MS = 100;
// pipes are written in whole Mbit/s from this bandwidth (Kbit/s) up, in Kbit/s below it
const MBIT_FROM = 20000;
// link framing, bytes per packet on top of the IP packet: Ethernet header for a plain
// link; DSL per RFC 2684 (ATM, LLC/SNAP bridged incl. AAL5 trailer) or PTM, plus PPPoE
const ETHERNET_HEADER = 14;
const DSL_OVERHEAD = ['atm' => 32, 'ptm' => 22];
const PPPOE_OVERHEAD = 8;
// TCP/IP headers of a full packet and the size of a TCP ACK (with timestamps)
const TCPIP_HEADERS = 40;
const ACK_BYTES = 52;

// a result more than this factor above the median of its hour, or an hour's best more than this
// above the median of the hours of its day, is left out (a measuring error)
const OUTLIER = 1.25;
// raising a pipe: to the lowest best of twice the days of results (at least RAISE_DAYS days with
// results, so two good nights in a row), but not above the lowering figure; only when at least a
// quarter of the minimum change above the pipe and not on the date after the pipe was lowered (the
// next daily update); "set now" (Apply now) is never held
const RAISE_DAYS = 2;
const RAISE_FROM = 0.25;
const RAISE_HOLD = 2;

// speedtest.csv columns
const CSV_TIMESTAMP = 0;
const CSV_DOWNLOAD = 5;
const CSV_UPLOAD = 6;

// per direction: rule direction, csv column and the names used when creating
const DIRECTIONS = [
    'download' => [
        'rule' => 'in',
        'column' => CSV_DOWNLOAD,
        'pipe' => 'WAN_download_p',
        'queue' => 'WAN_download_q',
        'rulename' => 'WAN to LAN',
    ],
    'upload' => [
        'rule' => 'out',
        'column' => CSV_UPLOAD,
        'pipe' => 'WAN_upload_p',
        'queue' => 'WAN_upload_q',
        'rulename' => 'LAN to WAN',
    ],
];

function finish($result)
{
    $msg = $result['message'] ?? $result['status'];
    // reopen: saving the config switches the syslog identity
    openlog('speedtest', LOG_ODELAY, LOG_USER);
    syslog($result['status'] == 'error' ? LOG_ERR : LOG_NOTICE, 'shaper: ' . $msg);
    if (($GLOBALS['action'] ?? '') == 'set' && $result['status'] != 'disabled') {
        history_add($result);
    }
    echo json_encode($result) . PHP_EOL;
    exit(0);
}

/**
 * the history rows, oldest first (backfilled from syslog when there is no history file yet)
 */
function history_rows()
{
    if (!file_exists(HISTORY_FILE)) {
        history_write(history_from_syslog());
    }
    $rows = [];
    if (($fh = @fopen(HISTORY_FILE, 'r')) !== false) {
        fgetcsv($fh, 0, ',', '"', '\\'); // header
        while (($row = fgetcsv($fh, 0, ',', '"', '\\')) !== false) {
            if (count($row) == count(HISTORY_HEADER)) {
                $rows[] = array_combine(HISTORY_HEADER, $row);
            }
        }
        fclose($fh);
    }
    return $rows;
}

function history_write($rows)
{
    $tmp = HISTORY_FILE . '.tmp';
    if (($fh = @fopen($tmp, 'w')) === false) {
        return;
    }
    fputcsv($fh, HISTORY_HEADER, ',', '"', '\\');
    foreach (array_slice($rows, -HISTORY_ROWS) as $row) {
        fputcsv($fh, array_map(function ($column) use ($row) {
            return $row[$column] ?? '';
        }, HISTORY_HEADER), ',', '"', '\\');
    }
    fclose($fh);
    rename($tmp, HISTORY_FILE);
}

/**
 * add the result of a set run to the history
 */
function history_add($result)
{
    $mbit = function ($value) {
        return $value === null ? '' : sprintf('%.3f', $value);
    };
    $row = ['time (UTC)' => gmdate('Y-m-d H:i:s'), 'status' => $result['status'], 'basis' => $result['basis'] ?? '',
        'message' => $result['status'] == 'error' ? $result['message'] : ''];
    foreach (DIRECTIONS as $dir => $props) {
        $row["$dir before (Mbit/s)"] = $mbit($result[$dir]['current_mbit'] ?? null);
        $row["$dir after (Mbit/s)"] = $mbit($result[$dir]['after_mbit'] ?? null);
        $row[$dir] = $result[$dir]['note'] ?? '';
        $row["best $dir (Mbit/s)"] = $mbit($result[$dir]['best_mbit'] ?? null);
        $row["raise $dir (Mbit/s)"] = $mbit($result[$dir]['raise_best_mbit'] ?? null);
    }
    $rows = history_rows();
    $rows[] = $row;
    history_write($rows);
}

/**
 * the set runs still in the system log (all versions of its message), oldest first
 */
function history_from_syslog()
{
    $rows = [];
    foreach (glob(SYSLOG_FILES) ?: [] as $file) {
        if (($fh = @fopen($file, 'r')) === false) {
            continue;
        }
        while (($line = fgets($fh)) !== false) {
            if (strpos($line, ' speedtest ') === false || strpos($line, '] shaper: ') === false ||
                !preg_match('/^<\d+>1 (\S+) .*?\] shaper: (.*)$/', rtrim($line), $m)) {
                continue;
            }
            $row = history_parse($m[2]);
            if ($row !== null && ($time = strtotime($m[1])) !== false) {
                $row['time (UTC)'] = gmdate('Y-m-d H:i:s', $time);
                $rows[$row['time (UTC)'] . $m[2]] = $row;
            }
        }
        fclose($fh);
    }
    ksort($rows);
    return array_values($rows);
}

/**
 * a history row from a shaper message of the system log, null when it is not about setting the pipes
 */
function history_parse($msg)
{
    if (preg_match('/^(no speedtest results|no (download|upload) pipe found|more than one (download|upload) pipe)/', $msg)) {
        return ['status' => 'error', 'message' => $msg];
    }
    if (!preg_match('/^download \S+: (.*?); upload \S+: (.*)$/', $msg, $m)) {
        return null;
    }
    // the basis is the last parenthesized part of the message
    $upload = $m[2];
    $basis = '';
    if (substr($upload, -1) == ')') {
        for ($i = strlen($upload) - 1, $depth = 0; $i >= 0; $i--) {
            $depth += $upload[$i] == ')' ? 1 : ($upload[$i] == '(' ? -1 : 0);
            if ($depth == 0) {
                break;
            }
        }
        $basis = substr($upload, $i + 1, -1);
        $upload = rtrim(substr($upload, 0, $i));
    }
    $row = ['status' => 'unchanged', 'basis' => $basis, 'message' => ''];
    foreach (['download' => $m[1], 'upload' => $upload] as $dir => $text) {
        if (!preg_match('/^([\d.]+)(?: to ([\d.]+))? (Mbit|Kbit)\/s,? ?(.*)$/', $text, $d)) {
            return null;
        }
        $scale = $d[3] == 'Kbit' ? 0.001 : 1;
        $row["$dir before (Mbit/s)"] = sprintf('%.3f', $d[1] * $scale);
        $row["$dir after (Mbit/s)"] = sprintf('%.3f', ($d[2] !== '' ? $d[2] : $d[1]) * $scale);
        $note = $d[4];
        if ($d[2] !== '') {
            $row['status'] = 'updated';
            // "(raised), CoDel target 27 ms" -> "raised, CoDel target 27 ms"; older versions: "changed"
            $note = preg_replace('/^\(([^()]*)\)/', '$1', $note);
            $note = $note === '' || strpos($note, 'CoDel') === 0 ? trim('changed, ' . $note, ', ') : $note;
        }
        $row[$dir] = $note;
    }
    return $row;
}

/**
 * the values without those more than OUTLIER above their median
 */
function without_outliers($values)
{
    sort($values);
    $n = count($values);
    $median = $n % 2 ? $values[intdiv($n, 2)] : ($values[$n / 2 - 1] + $values[$n / 2]) / 2;
    return array_filter($values, function ($value) use ($median) {
        return $value <= $median * OUTLIER;
    });
}

/**
 * the best download and upload (Mbit/s) of each of the last $days days (24 hours back from now,
 * day 0 the latest): the best result of each hour, then the best hour of the day, leaving out
 * the outliers of either step. Taking the best leaves out the slow servers and busy hours, so
 * every result counts, whatever the number of regions in its hour.
 */
function speedtest_days($days)
{
    // the csv timestamp is the UTC time read as local time, compare in the same terms
    $now = time() - (int)date('Z');
    $since = $now - $days * 86400;
    $hours = [];
    $probes = 0;
    if (($fh = @fopen(CSV_FILE, 'r')) !== false) {
        fgetcsv($fh, 0, ',', '"', '\\'); // header
        while (($row = fgetcsv($fh, 0, ',', '"', '\\')) !== false) {
            if (isset($row[CSV_UPLOAD]) && is_numeric($row[CSV_TIMESTAMP]) && $row[CSV_TIMESTAMP] >= $since &&
                is_numeric($row[CSV_DOWNLOAD]) && is_numeric($row[CSV_UPLOAD]) &&
                $row[CSV_DOWNLOAD] > 0 && $row[CSV_UPLOAD] > 0) {
                // day 0 the last 24 hours; a result at the very start of the window counts for the oldest day
                $day = min($days - 1, intdiv(max(0, $now - (int)$row[CSV_TIMESTAMP]), 86400));
                $hours[$day][intdiv((int)$row[CSV_TIMESTAMP], 3600)][] = $row;
                $probes++;
            }
        }
        fclose($fh);
    }
    if ($probes == 0) {
        return null;
    }
    ksort($hours);
    $result = ['days' => $days, 'hours' => array_sum(array_map('count', $hours)), 'probes' => $probes,
        'dayscount' => count($hours)];
    foreach (DIRECTIONS as $dir => $props) {
        // day => best hour of the best result of each hour
        $result[$dir] = array_map(function ($day) use ($props) {
            return max(without_outliers(array_map(function ($rows) use ($props) {
                return max(without_outliers(array_map('floatval', array_column($rows, $props['column']))));
            }, $day)));
        }, $hours);
    }
    return $result;
}

/**
 * the link behind the interface: its MTU (as configured now, e.g. 1492 for PPPoE or 1500
 * with RFC 4638 mini jumbo frames), PPPoE or not, and the DSL type set in the settings
 */
function wan_link($interface, $dsltype)
{
    $realif = get_real_interface($interface);
    $details = legacy_interface_details($realif);
    $link = [
        'mtu' => !empty($details['mtu']) ? (int)$details['mtu'] : 1500,
        'pppoe' => strpos($realif, 'pppoe') === 0,
        'dsl' => isset(DSL_OVERHEAD[$dsltype]) ? $dsltype : '',
    ];
    $link['overhead'] = $link['dsl'] != '' ?
        DSL_OVERHEAD[$link['dsl']] + ($link['pppoe'] ? PPPOE_OVERHEAD : 0) : ETHERNET_HEADER;
    return $link;
}

/**
 * bytes on the line for an IP packet of $bytes: ATM sends 48 bytes in each 53 byte cell
 * (the last one padded), PTM adds 1 byte per 64
 */
function wire_bytes($bytes, $link)
{
    $bytes += $link['overhead'];
    if ($link['dsl'] == 'atm') {
        return (int)ceil($bytes / 48) * 53;
    } elseif ($link['dsl'] == 'ptm') {
        return $bytes * 65 / 64;
    }
    return $bytes;
}

/**
 * upload bandwidth (Kbit/s) for a DSL line: the speedtest measures full packets, while the
 * download's ACKs take much more of the line than the shaper counts for them (ATM: a 52
 * byte ACK takes 106 bytes); reserve the line for one ACK per two full packets at the
 * download pipe's rate and give the rest to full packets. Never below half of $kbit.
 */
function dsl_upload($kbit, $download_kbit, $link)
{
    $full = wire_bytes($link['mtu'], $link);
    // line capacity the result stands for: goodput of full packets -> bytes on the line
    $line = $kbit * $full / ($link['mtu'] - TCPIP_HEADERS);
    $acks = $download_kbit * 1000 / (2 * $link['mtu'] * 8);
    $ack_line = $acks * wire_bytes(ACK_BYTES, $link) * 8 / 1000;
    $bulk = max(0, $line - $ack_line) * $link['mtu'] / $full;
    return max($kbit / 2, $bulk + $acks * ACK_BYTES * 8 / 1000);
}

/**
 * pipes per direction: through the rules on the interface, else by name
 * @return array direction => list of pipe uuids
 */
function discover_pipes($shaper, $interface, $by_name = true)
{
    $queue_pipe = [];
    foreach ($shaper->queues->queue->iterateItems() as $uuid => $queue) {
        $queue_pipe[$uuid] = (string)$queue->pipe;
    }
    $pipes = [];
    foreach ($shaper->pipes->pipe->iterateItems() as $uuid => $pipe) {
        $pipes[$uuid] = (string)$pipe->description;
    }
    $found = [];
    foreach (DIRECTIONS as $dir => $props) {
        $found[$dir] = [];
    }
    foreach ($shaper->rules->rule->iterateItems() as $rule) {
        if ((string)$rule->enabled != '1' || (string)$rule->interface != $interface) {
            continue;
        }
        $target = (string)$rule->target;
        $pipe = isset($pipes[$target]) ? $target : ($queue_pipe[$target] ?? null);
        if ($pipe === null) {
            continue;
        }
        foreach (DIRECTIONS as $dir => $props) {
            // a rule without direction matches both
            if (in_array((string)$rule->direction, ['', $props['rule']]) && !in_array($pipe, $found[$dir])) {
                $found[$dir][] = $pipe;
            }
        }
    }
    foreach (DIRECTIONS as $dir => $props) {
        if (empty($found[$dir]) && $by_name) {
            $named = array_keys($pipes, $props['pipe'], true);
            if (count($named) == 1) {
                $found[$dir] = $named;
            }
        }
    }
    return $found;
}

function pipe_kbit($pipe)
{
    $factor = ['bit' => 0.001, 'Kbit' => 1, 'Mbit' => 1000, 'Gbit' => 1000000];
    return (int)round((float)(string)$pipe->bandwidth * ($factor[(string)$pipe->bandwidthMetric] ?? 1));
}

/**
 * pipe setting for a bandwidth: whole Mbit/s from MBIT_FROM Kbit/s up, else Kbit/s (below 20 Mbit/s
 * a whole Mbit/s is 5% or more); rounded down so the pipe stays at or below the threshold
 */
function pipe_target($kbit)
{
    if ($kbit >= MBIT_FROM) {
        $target = ['bandwidth' => (int)floor($kbit / 1000), 'metric' => 'Mbit'];
        $target['kbit'] = $target['bandwidth'] * 1000;
    } else {
        $target = ['bandwidth' => max(1, (int)floor($kbit)), 'metric' => 'Kbit'];
        $target['kbit'] = $target['bandwidth'];
    }
    return $target;
}

/**
 * CoDel target and interval of a pipe that uses CoDel, for its bandwidth: on a slow pipe one
 * full-size packet (as sent on the link) takes longer than the default target (5 ms), so the target
 * becomes that time and the interval grows by as much (as sqm-scripts does), so CoDel does not drop
 * before a few packets could be sent; both go back to the default once the pipe is fast enough. A
 * lower target is left alone, and so is an interval that is not the default (empty or written out) or the
 * one set here.
 * @return string addition to the message, empty when nothing changed
 */
function codel_target($pipe, $kbit, $link)
{
    if ((string)$pipe->scheduler != 'fq_codel' && (string)$pipe->codel_enable != '1') {
        return '';
    }
    // the interval that goes with a target ('' is the default)
    $interval_for = function ($target) {
        return $target !== '' && (int)$target > CODEL_TARGET_MS ?
            (string)(CODEL_INTERVAL_MS + (int)$target - CODEL_TARGET_MS) : '';
    };
    $ms = (int)ceil(wire_bytes($link['mtu'], $link) * 8 / $kbit);
    $current = (string)$pipe->codel_target;
    $interval = (string)$pipe->codel_interval;
    $new = $current;
    if ($ms > CODEL_TARGET_MS) {
        $new = (string)$ms;
    } elseif ($current !== '' && (int)$current > CODEL_TARGET_MS) {
        $new = '';
    }
    $default = $interval === '' || $interval === (string)CODEL_INTERVAL_MS;
    $new_interval = $default || $interval === $interval_for($current) ? $interval_for($new) : $interval;
    if ($new_interval === '' && $default) {
        // the default written out stays as it is
        $new_interval = $interval;
    }
    if ($new === $current && $new_interval === $interval) {
        return '';
    }
    $pipe->codel_target = $new;
    $pipe->codel_interval = $new_interval;
    if ($new === '') {
        return $new_interval === '' ? ', CoDel target and interval back to default' : ', CoDel target back to default';
    }
    return sprintf(', CoDel target %d ms', $ms) .
        ($new_interval !== $interval_for($new) ? '' : sprintf(', interval %d ms', (int)$new_interval));
}

function shaper_apply()
{
    $backend = new Backend();
    $backend->configdRun('template reload OPNsense/Shaper');
    $backend->configdRun('template reload OPNsense/IPFW');
    foreach (['shaper reload', 'ipfw reload'] as $cmd) {
        $ret = trim($backend->configdRun($cmd));
        if ($ret != 'OK') {
            return "$cmd: $ret";
        }
    }
    return null;
}

/**
 * validate and write the shaper model to the config (not applied yet)
 */
function save_shaper($shaper)
{
    $errors = [];
    foreach ($shaper->performValidation() as $msg) {
        $errors[] = $msg->getField() . ': ' . $msg->getMessage();
    }
    if (!empty($errors)) {
        return implode(', ', $errors);
    }
    $shaper->serializeToConfig();
    Config::getInstance()->save();
    return null;
}

/**
 * uuid of the item in $items with this description, null when there is none
 * (or more than one) or it does not match $filter
 */
/**
 * The rules exclude the interface address, so the firewall's own traffic and
 * with it the speedtest is not shaped. Keep that exclusion current: replace the
 * previously recorded address in the rules on the interface by the current one.
 */
function sync_exclusion($mdl, $interface)
{
    $current = get_interface_ip($interface);
    $stored = (string)$mdl->shaper->address;
    if (empty($current)) {
        return ['status' => 'unchanged', 'message' => "interface $interface has no IPv4 address, exclusion not checked"];
    }
    if ($stored == $current) {
        return ['status' => 'unchanged', 'message' => "excluded address $current is current"];
    }
    $updated = 0;
    if ($stored != '') {
        $shaper = new TrafficShaper();
        foreach ($shaper->rules->rule->iterateItems() as $rule) {
            if ((string)$rule->interface != $interface) {
                continue;
            }
            foreach (['destination' => 'in', 'source' => 'out'] as $field => $direction) {
                $not = $field . '_not';
                if (
                    in_array((string)$rule->direction, ['', $direction]) &&
                    (string)$rule->$not == '1' && (string)$rule->$field == $stored
                ) {
                    $rule->$field = $current;
                    $updated++;
                }
            }
        }
        if ($updated > 0) {
            $err = save_shaper($shaper) ?? shaper_apply();
            if ($err !== null) {
                return ['status' => 'error', 'message' => $err];
            }
        }
    }
    $mdl->shaper->address = $current;
    $mdl->serializeToConfig();
    Config::getInstance()->save();
    return [
        'status' => $updated > 0 ? 'updated' : 'unchanged',
        'message' => $stored == '' ? "excluded address recorded as $current" :
            sprintf('excluded address changed from %s to %s in %d rule(s)', $stored, $current, $updated),
    ];
}

function find_named($items, $description, $filter = null)
{
    $match = [];
    foreach ($items->iterateItems() as $uuid => $item) {
        if ((string)$item->description == $description && ($filter === null || $filter($item))) {
            $match[] = $uuid;
        }
    }
    return count($match) == 1 ? $match[0] : null;
}

/**
 * MSS clamping of the interface: the interface "MSS" setting is an MTU, the firewall
 * clamps TCP to it minus 40 (IPv4); needed when the MTU is below 1500 (PPPoE)
 */
function mss_status($interface)
{
    $link = wan_link($interface, '');
    $mss = (string)(Config::getInstance()->object()->interfaces->$interface->mss ?? '');
    $result = ['interface' => $interface, 'mtu' => $link['mtu'], 'mss' => $mss];
    if (is_numeric($mss) && (int)$mss <= $link['mtu']) {
        $result['status'] = 'on';
        $result['message'] = sprintf('Enabled (TCP MSS %d, MTU %d)', (int)$mss - TCPIP_HEADERS, $link['mtu']);
    } elseif ($link['mtu'] >= 1500 && !is_numeric($mss)) {
        $result['status'] = 'unneeded';
        $result['message'] = sprintf('N/A (MTU %d)', $link['mtu']);
    } else {
        $result['status'] = 'missing';
        $result['message'] = is_numeric($mss) ?
            sprintf('too high: MSS setting %d is above the MTU %d', (int)$mss, $link['mtu']) :
            sprintf('missing (MTU %d)', $link['mtu']);
    }
    return $result;
}

$action = $argv[1] ?? '';
// Apply now on the page: settings take effect at once, a raise is not held
$applynow = $action == 'set' && ($argv[2] ?? '') == 'now';
if (!in_array($action, ['set', 'create', 'rules', 'sync', 'mss', 'setmss', 'history', 'clearhistory'])) {
    echo json_encode(['status' => 'error', 'message' =>
        'usage: shaper.php set [now]|create|sync|mss|setmss|history [csv]|clearhistory']) . PHP_EOL;
    exit(0);
}
if ($action == 'history') {
    $rows = history_rows();
    if (($argv[2] ?? '') == 'csv') {
        readfile(HISTORY_FILE);
    } else {
        echo json_encode(array_reverse($rows)) . PHP_EOL;
    }
    exit(0);
}
if ($action == 'clearhistory') {
    // an empty history (not a missing one, that would be filled from syslog again)
    history_write([]);
    echo json_encode(['status' => 'ok']) . PHP_EOL;
    exit(0);
}

openlog('speedtest', LOG_ODELAY, LOG_USER);
$lock = fopen(LOCK_FILE, 'a+');
if ($action != 'rules' && !flock($lock, LOCK_EX | LOCK_NB)) {
    finish(['status' => 'error', 'message' => 'another shaper update is running']);
}

$mdl = new Speedtest();
$settings = $mdl->shaper;
$interface = (string)$settings->interface;
if ($action == 'sync') {
    finish(sync_exclusion($mdl, $interface));
}
if ($action == 'mss') {
    echo json_encode(mss_status($interface)) . PHP_EOL;
    exit(0);
}
if ($action == 'setmss') {
    $status = mss_status($interface);
    if ($status['status'] != 'missing') {
        finish(['status' => 'unchanged', 'message' => 'MSS clamping ' . $status['message']]);
    }
    Config::getInstance()->object()->interfaces->$interface->mss = (string)$status['mtu'];
    Config::getInstance()->save();
    (new Backend())->configdRun('filter reload');
    finish(['status' => 'updated', 'message' => sprintf('MSS clamping set on %s: MSS setting %d (TCP MSS %d)',
        $interface, $status['mtu'], $status['mtu'] - TCPIP_HEADERS)]);
}
if ($action == 'set' && (string)$settings->enabled != '1') {
    finish(['status' => 'disabled', 'message' => 'setting the shaper bandwidth is disabled']);
}
// in case an address change was missed, the pipes are set after the exclusion is current
$sync = $action == 'set' ? sync_exclusion($mdl, $interface) : null;
if ($sync !== null && $sync['status'] == 'error') {
    finish($sync);
}

$days = (int)(string)$settings->days;
$thresholds = ['download' => (int)(string)$settings->threshold_down, 'upload' => (int)(string)$settings->threshold_up];
$link = wan_link($interface, (string)$settings->dsltype);
// figures for lowering (the best day of the days of results) and raising (the lowest best of twice
// as many days, not above the lowering one; none without RAISE_DAYS days of results)
$best = ['lower' => speedtest_days($days), 'raise' => speedtest_days($days * RAISE_DAYS)];
if ($best['lower'] === null) {
    finish(['status' => 'error', 'message' => sprintf('no speedtest results of the last %d day(s)', $days)]);
}
$figure = [];
foreach (DIRECTIONS as $dir => $props) {
    $figure['lower'][$dir] = max($best['lower'][$dir]);
    if ($best['raise']['dayscount'] >= RAISE_DAYS) {
        $figure['raise'][$dir] = min(min($best['raise'][$dir]), $figure['lower'][$dir]);
    }
}
$result = ['status' => 'unchanged', 'interface' => $interface, 'days' => $days, 'probes' => $best['lower']['probes'],
    'hours' => $best['lower']['hours'], 'thresholds' => $thresholds, 'link' => $link];
$targets = [];
foreach ($figure as $use => $figures) {
    $kbit = [];
    foreach (DIRECTIONS as $dir => $props) {
        $kbit[$dir] = $figures[$dir] * 1000 * $thresholds[$dir] / 100;
    }
    if ($link['dsl'] != '') {
        $kbit['upload'] = dsl_upload($kbit['upload'], pipe_target($kbit['download'])['kbit'], $link);
    }
    foreach (DIRECTIONS as $dir => $props) {
        $targets[$use][$dir] = pipe_target($kbit[$dir]);
    }
}
foreach (DIRECTIONS as $dir => $props) {
    $result[$dir] = ['estimate_mbit' => round($figure['lower'][$dir], 2), 'target_mbit' => $targets['lower'][$dir]['kbit'] / 1000,
        'raise_mbit' => isset($targets['raise']) ? $targets['raise'][$dir]['kbit'] / 1000 : null,
        'best_mbit' => $figure['lower'][$dir], 'raise_best_mbit' => $figure['raise'][$dir] ?? null];
}
$days_of = function ($figures) {
    return sprintf('%d of the last %d day(s), %d hours, %d results', $figures['dayscount'], $figures['days'],
        $figures['hours'], $figures['probes']);
};
$basis = sprintf(
    ' (best of %s; for raising lowest best of %s; download x %d%%, upload x %d%%%s)',
    $days_of($best['lower']),
    $best['raise'] !== null ? $days_of($best['raise']) : 'none',
    $thresholds['download'],
    $thresholds['upload'],
    $link['dsl'] != '' ? sprintf(', %s%s MTU %d', strtoupper($link['dsl']), $link['pppoe'] ? ' PPPoE' : '', $link['mtu']) : ''
);

$result['basis'] = substr($basis, 2, -1);

$shaper = new TrafficShaper();
$found = discover_pipes($shaper, $interface);
$changed = false;

if ($action == 'set') {
    $minchange = (int)(string)$settings->minchange;
    $msgs = [];
    foreach (DIRECTIONS as $dir => $props) {
        if (count($found[$dir]) != 1) {
            finish(['status' => 'error', 'message' => sprintf(
                count($found[$dir]) == 0 ?
                    'no %s pipe found for interface %s, use "Create shaper"' :
                    'more than one %s pipe found for interface %s, nothing changed',
                $dir,
                $interface
            )] + $result);
        }
    }
    $state = json_decode(@file_get_contents(STATE_FILE) ?: '{}', true);
    $state = is_array($state) ? $state : [];
    foreach (DIRECTIONS as $dir => $props) {
        $pipe = $shaper->getNodeByReference('pipes.pipe.' . $found[$dir][0]);
        $current = pipe_kbit($pipe);
        $result[$dir]['pipe'] = sprintf('%s (%s)', $pipe->description, $pipe->number);
        $result[$dir]['current_mbit'] = $current / 1000;
        $lower = $targets['lower'][$dir]['kbit'];
        // no raising figure without RAISE_DAYS days of results
        $raise = isset($targets['raise']) ? $targets['raise'][$dir]['kbit'] : 0;
        $down = $current > 0 ? ($current - $lower) * 100 / $current : 100;
        $up = $current > 0 ? ($raise - $current) * 100 / $current : 0;
        // dates since the pipe was lowered (local time), so the hold covers the next daily update
        // whether the pipe was lowered by that update or by Apply now later in the day
        $since = isset($state[$dir]) ?
            (int)round((strtotime('today') - strtotime('today', (int)$state[$dir])) / 86400) : PHP_INT_MAX;
        $target = null;
        $why = null;
        if ($current <= 0 || ($lower < $current && $down >= $minchange)) {
            $target = $targets['lower'][$dir];
            $why = 'lowered';
            $state[$dir] = time();
        } elseif ($raise > $current && $up >= $minchange * RAISE_FROM) {
            if ($since < RAISE_HOLD && $minchange > 0 && !$applynow) {
                $why = sprintf('raise to %.2f held, %d day(s) after it was lowered', $raise / 1000, $since);
            } else {
                $target = $targets['raise'][$dir];
                $why = $since < RAISE_HOLD && $minchange > 0 ? 'raised, hold skipped by Apply now' : 'raised';
            }
        }
        if ($target === null && (string)$pipe->bandwidthMetric != pipe_target($current)['metric']) {
            // a pipe in another unit than its bandwidth calls for (Kbit/s below MBIT_FROM, Mbit/s from
            // there) takes that unit, also inside the minimum change
            $target = pipe_target($current);
            $why = 'unit';
        }
        if ($target !== null) {
            $pipe->bandwidth = (string)$target['bandwidth'];
            $pipe->bandwidthMetric = $target['metric'];
            $result[$dir]['action'] = 'updated';
            $result[$dir]['after_mbit'] = $target['kbit'] / 1000;
            $codel = codel_target($pipe, $target['kbit'], $link);
            $result[$dir]['note'] = $why . $codel;
            $msgs[] = sprintf('%s %s: %.2f to %.2f Mbit/s (%s)', $dir, $pipe->description, $current / 1000,
                $target['kbit'] / 1000, $why) . $codel;
            $changed = true;
        } else {
            $result[$dir]['action'] = 'unchanged';
            $result[$dir]['after_mbit'] = $current / 1000;
            $result[$dir]['note'] = sprintf('kept (%s)', $why ?? sprintf(
                'lower %.2f, raise %s: change -%.1f%%/+%.1f%%, minimum -%s%%/+%s%%',
                $lower / 1000,
                isset($targets['raise']) ? sprintf('%.2f', $raise / 1000) : sprintf('none (%d days of results needed)', RAISE_DAYS),
                max(0, $down),
                max(0, $up),
                $minchange,
                $minchange * RAISE_FROM
            ));
            // a pipe kept at its bandwidth still takes the CoDel settings for it (e.g. set by an older version)
            $codel = codel_target($pipe, $current, $link);
            if ($codel !== '') {
                $result[$dir]['note'] .= $codel;
                $changed = true;
            }
            $msgs[] = sprintf('%s %s: %.2f Mbit/s %s', $dir, $pipe->description, $current / 1000, $result[$dir]['note']);
        }
    }
    $result['message'] = implode('; ', $msgs) . $basis;
    if ($sync['status'] == 'updated') {
        $result['message'] .= '; ' . $sync['message'];
    }
    if ($changed) {
        $err = save_shaper($shaper) ?? shaper_apply();
        if ($err !== null) {
            finish(['status' => 'error', 'message' => $err] + $result);
        }
        $result['status'] = 'updated';
        if (@file_put_contents(STATE_FILE, json_encode($state)) === false) {
            $result['message'] .= '; could not save ' . STATE_FILE;
        }
    }
} else {
    // only directions without rules on the interface; a pipe or queue left
    // by an earlier, unfinished run is reused by name
    $missing = array_keys(array_filter(discover_pipes($shaper, $interface, false), function ($pipes) {
        return empty($pipes);
    }));
    if (empty($missing)) {
        finish(['status' => 'exists', 'message' => "shaper rules already exist for interface $interface"] + $result);
    }
    $address = get_interface_ip($interface);
    if (empty($address)) {
        // the rules exclude the firewall's own address, so the speedtest itself is not shaped
        finish(['status' => 'error', 'message' => "interface $interface has no IPv4 address, nothing created"] + $result);
    }

    if ($action == 'create') {
        // pipes and queues, then the rules in a fresh process (see "rules" above)
        $msgs = [];
        foreach ($missing as $dir) {
            $props = DIRECTIONS[$dir];
            $pipe_uuid = find_named($shaper->pipes->pipe, $props['pipe']);
            if ($pipe_uuid === null) {
                $pipe = $shaper->pipes->pipe->Add();
                $pipe->number = $shaper->newPipeNumber();
                $pipe->bandwidth = (string)$targets['lower'][$dir]['bandwidth'];
                $pipe->bandwidthMetric = $targets['lower'][$dir]['metric'];
                $pipe->scheduler = 'fq_codel';
                $pipe->codel_ecn_enable = '1';
                $pipe->description = $props['pipe'];
                $pipe->origin = 'TrafficShaper';
                $pipe_uuid = $pipe->getAttribute('uuid');
                $msgs[] = sprintf('pipe %s (%.2f Mbit/s%s)', $props['pipe'], $targets['lower'][$dir]['kbit'] / 1000,
                    codel_target($pipe, $targets['lower'][$dir]['kbit'], $link));
            }
            $queue_uuid = find_named($shaper->queues->queue, $props['queue'], function ($queue) use ($pipe_uuid) {
                return (string)$queue->pipe == $pipe_uuid;
            });
            if ($queue_uuid === null) {
                $queue = $shaper->queues->queue->Add();
                $queue->number = $shaper->newQueueNumber();
                $queue->pipe = $pipe_uuid;
                $queue->weight = '100';
                $queue->description = $props['queue'];
                $queue->origin = 'TrafficShaper';
                $msgs[] = 'queue ' . $props['queue'];
            }
        }
        if (!empty($msgs)) {
            $err = save_shaper($shaper);
            if ($err !== null) {
                finish(['status' => 'error', 'message' => $err] + $result);
            }
        }
        $rules = json_decode(shell_exec(escapeshellarg(PHP_BINARY) . ' ' . escapeshellarg(__FILE__) . ' rules'), true) ??
            ['status' => 'error', 'message' => 'adding the rules failed'];
        $msgs = array_merge($msgs, $rules['created'] ?? []);
        $result['status'] = $rules['status'];
        $result['message'] = $rules['status'] == 'created' ?
            'created ' . implode(', ', $msgs) . " on $interface, excluding $address" :
            ($rules['message'] ?? $rules['status']) . (empty($msgs) ? '' : ' (created: ' . implode(', ', $msgs) . ')');
        foreach ($missing as $dir) {
            $result[$dir]['action'] = $rules['status'] == 'created' ? 'created' : 'incomplete';
            $result[$dir]['pipe'] = DIRECTIONS[$dir]['pipe'];
        }
    } else {
        $created = [];
        $sequence = (int)$shaper->getMaxRuleSequence();
        foreach ($missing as $dir) {
            $props = DIRECTIONS[$dir];
            $pipe_uuid = find_named($shaper->pipes->pipe, $props['pipe']);
            $queue_uuid = $pipe_uuid === null ? null :
                find_named($shaper->queues->queue, $props['queue'], function ($queue) use ($pipe_uuid) {
                    return (string)$queue->pipe == $pipe_uuid;
                });
            if ($queue_uuid === null) {
                finish(['status' => 'error', 'message' => "queue {$props['queue']} not found, no rules added"]);
            }
            $rule = $shaper->rules->rule->Add();
            $rule->sequence = (string)(++$sequence);
            $rule->interface = $interface;
            $rule->proto = 'ip';
            $rule->direction = $props['rule'];
            if ($props['rule'] == 'in') {
                $rule->destination = $address;
                $rule->destination_not = '1';
            } else {
                $rule->source = $address;
                $rule->source_not = '1';
            }
            $rule->target = $queue_uuid;
            $rule->description = $props['rulename'];
            $rule->origin = 'TrafficShaper';
            $created[] = sprintf('rule "%s"', $props['rulename']);
        }
        $err = save_shaper($shaper) ?? shaper_apply();
        if ($err !== null) {
            finish(['status' => 'error', 'message' => $err]);
        }
        // remember the excluded address, so sync can follow a change (saved here, as the
        // config of the create process predates these rules)
        $mdl->shaper->address = $address;
        $mdl->serializeToConfig();
        Config::getInstance()->save();
        $result = ['status' => 'created', 'message' => 'created ' . implode(', ', $created), 'created' => $created];
    }
}

finish($result);
