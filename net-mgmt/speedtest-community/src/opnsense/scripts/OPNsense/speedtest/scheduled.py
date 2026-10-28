#!/usr/local/bin/python3
"""
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

 scheduled speedtests against the servers that measured the line best:

   scheduled.py run       one scheduled speedtest (the cron task)
   scheduled.py servers   the ranking, for the page

 Servers are ranked by their own results of the last RANK_DAYS days: each result is
 scored against the fastest download of the same day, so a change of the line moves
 all servers alike, and a server's score is the median of its scores. The first
 interval of a night fetches the nearest servers ("Get server list"). Each interval
 runs "multiple" tests, each on another region (a provider's server in one location):
 the best ranked regions on that list. A region that keeps failing (RETRIES) is blocked
 until the next day, a second failing region of the same provider blocks all of its
 regions; the test moves on to the next region in the order of the list (speedtest's
 own recommendation), so an hour keeps as many regions as tests and a slow server
 can't fill it. Blocks only hold when another region answered in the interval: when
 the first STOP_AFTER regions all fail, the line or the client is at fault, the
 interval stops. Once a night (not on the first interval) a server of the list without
 enough results gets a trial, as an extra test, so the ranking can learn. Every test is
 saved in the results (csv) and logged to syslog; the shaper takes the best result of
 each hour.
"""
import csv
import json
import os
import statistics
import subprocess
import sys
import syslog
import time
import xml.etree.ElementTree as ET
from datetime import datetime

SCRIPT = '/usr/local/opnsense/scripts/OPNsense/speedtest/opn_speedtest.py'
CSVFILE = '/usr/local/opnsense/scripts/OPNsense/speedtest/speedtest.csv'
STATEFILE = '/usr/local/opnsense/scripts/OPNsense/speedtest/scheduled.json'
CONFIG = '/conf/config.xml'

RANK_DAYS = 30      # results used for the ranking
RANK_RESULTS = 2    # results a server needs to be ranked
PAUSE = 10          # seconds between the tests of an interval
RETRIES = [15, 30, 60]  # seconds before each retry of a failing region, then it is blocked
STOP_AFTER = 3      # regions failing in a row, before any answered, that stop an interval


def speedtest(*args):
    """ run opn_speedtest.py (a server id, '0' for speedtest's own pick, or 'list'); it always answers in json """
    proc = subprocess.run(['/usr/local/bin/python3', SCRIPT] + list(args),
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        return json.loads(proc.stdout.decode('utf-8'))
    except ValueError:
        return {'error': 'no json from opn_speedtest.py: ' + proc.stderr.decode('utf-8', 'replace').strip()[-200:]}


def multiple():
    """ speedtests at each interval, as set on the page (1 to 5) """
    try:
        node = ET.parse(CONFIG).getroot().find('OPNsense/speedtest/shaper/multiple')
        return max(1, min(5, int(node.text)))
    except (OSError, ET.ParseError, AttributeError, TypeError, ValueError):
        return 3


def provider(name):
    """ the provider of a server, from its name 'sponsor, location' (the name is its region) """
    return name.split(', ')[0]


def is_blocked(name, blocked):
    return name in blocked['regions'] or provider(name) in blocked['providers']


def block(name, blocked):
    """ block a region; a second region of the same provider blocks the provider; returns what was blocked """
    if any(provider(r) == provider(name) for r in blocked['regions']):
        blocked['providers'].append(provider(name))
        blocked['regions'].append(name)
        return '%s (all regions)' % provider(name)
    blocked['regions'].append(name)
    return name


def log(message):
    syslog.syslog(syslog.LOG_NOTICE, message)


def load_state():
    try:
        with open(STATEFILE, 'r', encoding='utf-8') as f:
            state = json.load(f)
        if isinstance(state, dict):
            return state
    except (OSError, ValueError):
        pass
    return {}


def save_state(state):
    tmp = STATEFILE + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(state, f)
    os.replace(tmp, STATEFILE)


def ranking(now=None):
    """
    servers of the last RANK_DAYS days: id => {name, results, score}; score is the
    median of download / fastest download of the same day, days with one result
    (nothing to compare with) count for the number of results only
    """
    now = now or time.time()
    days = {}
    try:
        with open(CSVFILE, 'r', encoding='utf-8') as f:
            data = csv.reader(f, dialect='excel')
            next(data, None)
            for row in data:
                try:
                    stamp, download = float(row[0]), float(row[5])
                except (IndexError, ValueError):
                    continue
                if stamp < now - RANK_DAYS * 86400 or download <= 0:
                    continue
                day = datetime.fromtimestamp(stamp).strftime('%Y-%m-%d')
                days.setdefault(day, []).append((str(row[2]), row[3], download))
    except OSError:
        return {}
    servers = {}
    for results in days.values():
        fastest = max(r[2] for r in results)
        for serverid, name, download in results:
            server = servers.setdefault(serverid, {'name': name, 'results': 0, 'scores': []})
            server['name'] = name
            server['results'] += 1
            if len(results) > 1:
                server['scores'].append(download / fastest)
    for server in servers.values():
        scores = server.pop('scores')
        server['score'] = round(statistics.median(scores), 3) if scores else None
    return servers


def ranked(servers):
    """ ids of the servers with enough results to be ranked, best first """
    ids = [i for i, s in servers.items() if s['results'] >= RANK_RESULTS and s['score'] is not None]
    return sorted(ids, key=lambda i: (-servers[i]['score'], -servers[i]['results']))


def test(pool, names, used, blocked, label, answered):
    """
    one speedtest on the first server of pool whose region was not used in this interval and
    is not blocked ('0': speedtest's own pick, region unknown). A failing server is retried
    after each of RETRIES, then its region is blocked (see block). Unless the interval
    answered already, STOP_AFTER failing regions stop the test.
    """
    messages = []
    failed = 0
    for serverid in pool:
        name = names.get(serverid, '') if serverid != '0' else None
        if name is not None and (name in used or is_blocked(name, blocked)):
            continue
        what = 'server %s (%s)' % (serverid, name) if serverid != '0' else 'speedtest\'s pick'
        for attempt in range(len(RETRIES) + 1):
            if attempt > 0:
                time.sleep(RETRIES[attempt - 1])
            result = speedtest(serverid)
            if 'error' not in result and 'download' in result:
                messages.append('%s %s: %s Mbit/s down, %s Mbit/s up' % (label, what, result['download'], result['upload']))
                log(messages[-1])
                used.add(result.get('servername', name))
                return result, messages
            messages.append('%s %s failed (attempt %d): %s' % (label, what, attempt + 1, result.get('error', result)))
            log(messages[-1])
        if name is not None:
            blocked['new'].append(block(name, blocked))
        failed += 1
        if not answered and failed >= STOP_AFTER:
            messages.append('%s stopped: %d regions failed in a row, the line or the speedtest client is likely at fault' %
                            (label, failed))
            log(messages[-1])
            return None, messages
    if len(pool) > 1:
        messages.append('%s skipped: no other region left' % label)
        log(messages[-1])
    return None, messages


def pool_of(state, servers, best, count):
    """
    the servers the tests of an interval go through: the count best ranked regions on the
    list, then the servers of the list in its order; without a list, the ranked servers and
    speedtest's own pick
    """
    listed = [s['id'] for s in state.get('list', [])]
    pool = [i for i in best if not listed or i in listed]
    if listed:
        return pool[:count] + [i for i in listed if i not in pool[:count]]
    return pool + ['0']


def blocked_of(state):
    """ tonight's blocks: regions and providers (all their regions) """
    return {'regions': list(state.get('blocked', [])), 'providers': list(state.get('blocked_providers', [])), 'new': []}


def run():
    state = load_state()
    night = datetime.now().strftime('%Y-%m-%d')
    first = state.get('night') != night
    messages = []
    if first:
        # a new night: fetch the nearest servers and keep the previous list to compare
        found = speedtest('list')
        if isinstance(found, list) and found:
            state['previous'] = state.get('list', [])
            state['list'] = [{'id': str(s['id']), 'name': s['name'] + ', ' + s['location']} for s in found]
            messages.append('server list: ' + ', '.join(s['id'] for s in state['list']))
        else:
            messages.append('server list failed, using the last one: ' +
                            (found.get('error', '') if isinstance(found, dict) else ''))
        log(messages[-1])
        state.update({'night': night, 'tests': 0, 'trial': None, 'blocked': [], 'blocked_providers': []})
    state['tests'] = state.get('tests', 0) + 1
    listed = [s['id'] for s in state.get('list', [])]
    previous = [s['id'] for s in state.get('previous', [])]

    servers = ranking()
    best = ranked(servers)
    count = multiple()
    pool = pool_of(state, servers, best, count)
    names = {i: s['name'] for i, s in servers.items()}
    names.update({s['id']: s['name'] for s in state.get('list', [])})
    save_state(state)

    # regions tested in this interval; blocks of this interval only hold when a region answered
    used = set()
    blocked = blocked_of(state)
    results = []
    tests = 0
    error = None
    for n in range(count):
        if n > 0:
            time.sleep(PAUSE)
        result, lines = test(pool, names, used, blocked, 'test %d/%d' % (n + 1, count), bool(results))
        tests += 1
        messages += lines
        if result is None:
            error = lines[-1]
            if pool[-1] != '0':
                # no region left, or the interval stopped
                break
        else:
            results.append(result)
    if results:
        for what in blocked['new']:
            messages.append('%s blocked until tomorrow' % what)
            log(messages[-1])
        state.update({'blocked': blocked['regions'], 'blocked_providers': blocked['providers']})
    elif blocked['new']:
        messages.append('no region answered, nothing blocked')
        log(messages[-1])
    save_state(state)

    if not first and not state.get('trial') and listed and results:
        # unranked servers of the list whose region was not tested in this interval and is not
        # blocked; the fewest trials first, then new on the list, then nearest
        trials = state.get('trials', {})
        blocked = blocked_of(state)
        unranked = [i for i in listed if i not in best and names[i] not in used and not is_blocked(names[i], blocked)]
        if unranked:
            trial = min(unranked, key=lambda i: (trials.get(i, 0), i in previous, listed.index(i)))
            trials[trial] = trials.get(trial, 0) + 1
            state.update({'trials': trials, 'trial': trial})
            save_state(state)
            # an extra test, on the trial server only
            time.sleep(PAUSE)
            result, lines = test([trial], names, used, blocked, 'trial', True)
            tests += 1
            messages += lines
            if result is None:
                messages.append('%s blocked until tomorrow' % blocked['new'][-1])
                log(messages[-1])
                state.update({'blocked': blocked['regions'], 'blocked_providers': blocked['providers']})
                save_state(state)
    out = {'tests': tests, 'results': len(results), 'scheduled': messages}
    if results:
        out['download'] = round(statistics.mean(r['download'] for r in results), 2)
        out['upload'] = round(statistics.mean(r['upload'] for r in results), 2)
    else:
        out['error'] = error or 'no server to test'
    print(json.dumps(out))


def servers_out():
    state = load_state()
    listed = [s['id'] for s in state.get('list', [])]
    names = {s['id']: s['name'] for s in state.get('list', [])}
    servers = ranking()
    best = ranked(servers)
    count = multiple()
    tonight = state.get('night') == datetime.now().strftime('%Y-%m-%d')
    blocked = blocked_of(state if tonight else {})
    out = []
    for i in best:
        out.append({'id': i, 'name': servers[i]['name'], 'score': servers[i]['score'],
                    'results': servers[i]['results'], 'listed': not listed or i in listed})
    # the servers the next interval would test, one per region
    candidates, seen = [], set()
    for i in pool_of(state, servers, best, count):
        name = servers[i]['name'] if i in servers else names.get(i, '')
        if i != '0' and name not in seen and not is_blocked(name, blocked) and len(candidates) < count:
            seen.add(name)
            candidates.append({'id': i, 'name': name, 'score': servers[i]['score'] if i in best else None})
    shown = blocked['providers'] + [r for r in blocked['regions'] if provider(r) not in blocked['providers']]
    shown = ['%s (all regions)' % b if b in blocked['providers'] else b for b in shown]
    print(json.dumps({'servers': out, 'candidates': candidates, 'blocked': shown,
                      'night': state.get('night', ''), 'trial': state.get('trial')}))


if __name__ == '__main__':
    syslog.openlog('speedtest', 0, syslog.LOG_USER)
    try:
        if len(sys.argv) > 1 and sys.argv[1] == 'servers':
            servers_out()
        else:
            run()
    except Exception as e:
        # never exit non-zero, configd only logs a traceback; return the reason as json
        print(json.dumps({'error': 'Scheduled speedtest failed: ' + type(e).__name__ + ': ' + str(e)}))
