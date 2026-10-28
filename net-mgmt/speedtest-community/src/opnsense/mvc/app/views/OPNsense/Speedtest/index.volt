{# Copyright 2021 Miha Kralj 
*    Redistribution and use in source and binary forms, with or without
*    modification, are permitted provided that the following conditions are met:
*
*    1. Redistributions of source code must retain the above copyright notice,
*       this list of conditions and the following disclaimer.
*
*    2. Redistributions in binary form must reproduce the above copyright
*       notice, this list of conditions and the following disclaimer in the
*       documentation and/or other materials provided with the distribution.
*
*    THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
*    INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
*    AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
*    AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
*    OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
*    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
*    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
*    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
*    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
*    POSSIBILITY OF SUCH DAMAGE.
#}
<style>
    /* every row of the page's tables centred vertically, the log switches on one line with their buttons */
    .content-box table > tbody > tr > td, .content-box table > thead > tr > th { vertical-align: middle; }
    .log-switch { display: flex; align-items: center; flex-wrap: wrap; gap: 0.5em; padding: 1ex 0; }
    .log-switch .btn { margin-left: 0.5em; }
    /* timestamps of the speedtest log and the pipe changes on one line */
    table.speedtest-log tr > :first-child, table.shaper-log tr > :first-child { white-space: nowrap; }
</style>
{# heading above its box like "Run speedtest" and "Traffic shaper", the page's help switch on the same line #}
<div style="display: flex; justify-content: space-between; align-items: baseline;">
    <h2>{{ lang._('Statistics') }}</h2>
    <span>
        <small>help </small>
        <i class="fa fa-toggle-off text-danger" style="cursor: pointer;" id="toggle_help_page"></i>
    </span>
</div>
{# same columns as the forms below (25/40/35), values span the last two #}
<div class="content-box">
    <table class="table table-condensed" style="table-layout: fixed; width: 100%;">
        <colgroup>
            <col style="width: 25%;" />
            <col style="width: 40%;" />
            <col style="width: 35%;" />
        </colgroup>
        <tbody>
            <tr>
                <td>Speedtest probes:</td>
                <td colspan="2">
                    <div id="stat_samples">0</div>
                </td>
            </tr>
            <tr>
                <td>Average Download speed:</td>
                <td colspan="2">
                    <div id="stat_download">0 Mbps (min: 0 Mbps, max: 0 Mbps)</div>
                </td>
            </tr>
            <tr>
                <td>Average Upload speed:</td>
                <td colspan="2">
                    <div id="stat_upload">0 Mbps (min: 0 Mbps, max: 0 Mbps)</div>
                </td>
            </tr>
            <tr>
                <td>Average Latency:</td>
                <td colspan="2">
                    <div id="stat_latency">0.00 ms (min: 0.00 ms, max: 0.00 ms)</div>
                </td>
            </tr>
        </tbody>
    </table>
</div>
{# the last test, hidden until one ran; heading above its own box like the others #}
<div id="test_results" style="display:none">
<h2>{{ lang._('Last speedtest') }}</h2>
<div class="content-box">
    <table class="table table-condensed" style="table-layout: fixed; width: 100%;">
        <colgroup>
            <col style="width: 25%;" />
            <col style="width: 40%;" />
            <col style="width: 35%;" />
        </colgroup>
        <tbody>
            <tr>
                <td>Download speed:</td>
                <td colspan="2" style="font-weight: bold;">
                    <div id="dlspeed"></div>
                </td>
            </tr>
            <tr>
                <td>Upload speed:</td>
                <td colspan="2" style="font-weight: bold;">
                    <div id="ulspeed"></div>
                </td>
            </tr>
            <tr>
                <td>Latency (ping):</td>
                <td colspan="2" style="font-weight: bold;">
                    <div id="latency"></div>
                </td>
            </tr>
            <tr>
                <td>Speedtest server:</td>
                <td colspan="2">
                    <div id="ISP1"></div>
                    <div id="ISP2"></div>
                    <div id="ISP3"></div>
                </td>
            </tr>
            <tr>
                <td>Client IP:</td>
                <td colspan="2">
                    <div id="client"></div>
                </td>
            </tr>
            <tr>
                <td>Result id:</td>
                <td colspan="2">
                    <div id="result"></div>
                </td>
            </tr>
        </tbody>
    </table>
</div>
</div>
<h2>Run speedtest</h2>
{# same markup as the core form of the Traffic shaper (layout_partials/base_form), so both boxes line up #}
<div class="content-box">
    <div>
        <div class="table-responsive form-inline">
        <table id="run_speedtest_table" class="table table-striped table-condensed" style="table-layout: fixed; width: 100%;">
            <colgroup>
                <col style="width: 25%;" />
                <col style="width: 40%;" />
                <col style="width: 35%;" />
            </colgroup>
            <tbody>
                <tr>
                    <td><div class="control-label"><b>{{ lang._('Speedtest module') }}</b></div></td>
                    <td>
                        <span id="module_status">{{ lang._('Locating speedtest module...') }}</span>
                        <div class="speedtest-help hidden">
                            <small>{{ lang._('Speedtest by Ookla (installed from install.speedtest.net). Its licence and GDPR terms are accepted on your behalf when a test runs.') }}</small>
                        </div>
                    </td>
                    <td>
                        <button class="btn btn-default" id="moduleInstallAct" type="button" style="display: none;">
                            <b id="moduleInstallAct_label"></b> <i id="moduleInstallAct_progress"></i></button>
                    </td>
                </tr>
                <tr id="module_output_row" style="display: none;">
                    <td colspan="3">
                        <pre id="module_output" style="white-space: pre-wrap; margin-bottom: 1ex;"></pre>
                        <button class="btn btn-default" id="moduleRefreshAct" type="button">
                            <b>{{ lang._('Refresh') }}</b></button>
                    </td>
                </tr>
                <tr class="canruntests" style="display: none;">
                    <td><div class="control-label"><b>{{ lang._('Server list') }}</b></div></td>
                    <td>
                        <select id="speedlist" class="form-control" style="width: 346px; max-width: 100%;">
                            <option value="">{{ lang._('automatic (nearest server)') }}</option>
                        </select>
                        <div class="speedtest-help hidden">
                            <small>{{ lang._('Populates server list. Defaults to nearest.') }}</small>
                        </div>
                    </td>
                    <td>
                        <button class="btn btn-default" id="serverlistAct" type="button">
                            <b>{{ lang._('Get server list') }}</b> <i id="serverlistAct_progress"></i></button>
                    </td>
                </tr>
                <tr class="canruntests" style="display: none;">
                    <td><div class="control-label"><b>{{ lang._('Server id') }}</b></div></td>
                    <td>
                        <input type="text" id="serverid" name="serverid" class="form-control" size="50"
                               inputmode="numeric" placeholder="{{ lang._('optional') }}">
                        <div class="speedtest-help hidden">
                            <small>{{ lang._('Leave empty to let speedtest pick the nearest server, or enter the id of a specific server.') }}</small>
                        </div>
                        <small id="serverid_error" class="text-danger" style="display:none"></small>
                    </td>
                    <td>
                        <button class="btn btn-default" id="reportAct" type="button">
                            <b>{{ lang._('run speedtest') }}</b> <i id="reportAct_progress"></i></button>
                    </td>
                </tr>
            </tbody>
        </table>
        </div>
        <div class="canruntests" style="display: none;">
        {{ partial("layout_partials/base_form",['fields':scheduleForm,'id':'frm_schedule'])}}
        <div class="col-md-12">
            <button class="btn btn-primary" id="scheduleSaveAct" type="button">
                <b>{{ lang._('Save') }}</b> <i id="scheduleSaveAct_progress"></i></button>
            <button class="btn btn-default" id="scheduleApplyAct" type="button">
                <b>{{ lang._('Apply now') }}</b> <i id="scheduleApplyAct_progress"></i></button>
            <div id="schedule_result" style="margin-top: 1ex;"></div>
        </div>
        <div class="clearfix"></div>
        </div>
        <div class="col-md-12">
            <div class="log-switch">
                <a href="#" class="log-toggle" data-rows="speedtest-log"><i class="fa fa-toggle-off text-danger"></i></a>
                <span>{{ lang._('show log') }}</span>
                <span class="speedtest-log" style="display: none;">
                    <a href="/api/speedtest/download/csv" class="btn btn-sm btn-primary"><b>{{ lang._('Export log') }}</b></a>
                    <button class="btn btn-sm btn-primary" id="deletelogAct" type="button">
                        <b>{{ lang._('Clear log') }}</b> <i id="deletelogAct_progress"></i></button>
                </span>
            </div>
            <table class="table table-condensed speedtest-log" style="display: none;">
                <thead>
                    <tr>
                        <th class="text-center">{{ lang._('Timestamp (GMT)') }}</th>
                        <th class="text-center">{{ lang._('Server id') }}</th>
                        <th class="text-center">{{ lang._('Server name') }}</th>
                        <th class="text-center">{{ lang._('Download') }}</th>
                        <th class="text-center">{{ lang._('Upload') }}</th>
                        <th class="text-center">{{ lang._('Latency') }}</th>
                    </tr>
                </thead>
                <tbody id="log_block"></tbody>
            </table>
        </div>
        <div class="clearfix"></div>
    </div>
</div>

<h2>{{ lang._('Traffic shaper') }}</h2>
<div class="content-box" id="shaper">
    {{ partial("layout_partials/base_form",['fields':shaperForm,'id':'frm_shaper'])}}
    <div class="col-md-12">
        <button class="btn btn-primary" id="shaperSaveAct" type="button">
            <b>{{ lang._('Save') }}</b> <i id="shaperSaveAct_progress"></i></button>
        <button class="btn btn-default" id="shaperApplyAct" type="button">
            <b>{{ lang._('Apply now') }}</b> <i id="shaperApplyAct_progress"></i></button>
        <button class="btn btn-default" id="shaperCreateAct" type="button">
            <b>{{ lang._('Create shaper') }}</b> <i id="shaperCreateAct_progress"></i></button>
        <button class="btn btn-default" id="mssSetAct" type="button" style="display: none;">
            <b>{{ lang._('Set MSS clamping') }}</b> <i id="mssSetAct_progress"></i></button>
        <div id="shaper_result" style="margin-top: 1ex;"></div>
    </div>
    <div class="col-md-12">
        <div class="log-switch">
            <a href="#" class="log-toggle" data-rows="shaper-log"><i class="fa fa-toggle-off text-danger"></i></a>
            <span>{{ lang._('show changes') }}</span>
            <span class="shaper-log" style="display: none;">
                <a href="/api/speedtest/shaper/export" class="btn btn-sm btn-primary"><b>{{ lang._('Export') }}</b></a>
                <button class="btn btn-sm btn-primary" id="clearhistoryAct" type="button">
                    <b>{{ lang._('Clear') }}</b> <i id="clearhistoryAct_progress"></i></button>
            </span>
        </div>
        <table class="table table-condensed shaper-log" style="display: none;">
            <thead>
                <tr>
                    <th class="text-center">{{ lang._('Timestamp (GMT)') }}</th>
                    <th class="text-center">{{ lang._('Download') }}</th>
                    <th class="text-center">{{ lang._('Upload') }}</th>
                    <th class="text-center">{{ lang._('Best down / up') }}</th>
                    <th class="text-center">{{ lang._('Based on') }}</th>
                </tr>
            </thead>
            <tbody id="history_block"></tbody>
        </table>
        <div class="speedtest-help hidden">
            <small>{{ lang._('Each update of the pipes (the daily task and Apply now): the pipe before and after, why, the best results it was set from (lowering, and raising in brackets) and the results they are based on. Runs before this list was kept are taken from the system log, without the best results.') }}</small>
        </div>
    </div>
    <div class="clearfix"></div>
</div>

<script>
    function stat_reload() {
        ajaxCall(url = "/api/speedtest/service/showstat", sendData = {}, callback = function(l, status) {
            $('#stat_samples').html("<b>" + l.samples + "<\/b>")
            $('#stat_latency').html("<b>" + l.latency.avg + " ms<\/b> (min: " + l.latency.min + " ms, max: " + l.latency.max + " ms)")
            $('#stat_download').html("<b>" + l.download.avg + " Mbps<\/b> (min: " + l.download.min + " Mbps, max: " + l.download.max + " Mbps)")
            $('#stat_upload').html("<b>" + l.upload.avg + " Mbps<\/b> (min: " + l.upload.min + " Mbps, max: " + l.upload.max + " Mbps)")
        });
    };
    function log_reload() {
        ajaxCall(url = "/api/speedtest/service/showlog", sendData = {}, callback = function(l, status) {
            var obj = '';
            for (var i = 0; i < l.length; i++) {
                obj +=
                    "<tr><td class=\"text-center\" style=\"\">" + l[i][0] + "</td>" +
                    "<td class=\"text-center\" style=\"\">" + l[i][2] + "</td>" +
                    "<td class=\"text-center\" style=\"\">" + l[i][3] + "</td>" +
                    "<td class=\"text-center\" style=\"\">" + parseFloat(l[i][5]).toFixed(2) + "</td>" +
                    "<td class=\"text-center\" style=\"\">" + parseFloat(l[i][6]).toFixed(2) + "</td>" +
                    "<td class=\"text-center\" style=\"\">" + parseFloat(l[i][7]).toFixed(2) + "</td></tr>"
            }
            $('#log_block').html(obj);
        });
    };
    // the rows of "Run speedtest" and of the schedule form below it alternate like one striped
    // table, starting with the striped colour as the Traffic shaper form does: hidden rows still
    // count for the theme's stripes, so hidden padding rows put each visible row in its place
    function speedtest_stripes() {
        var n = 0;
        $('#run_speedtest_table > tbody, #frm_schedule table > tbody').each(function() {
            $(this).children('tr.stripe-pad').remove();
            $(this).children('tr').filter(function() { return this.style.display !== 'none'; }).each(function() {
                if (($(this).index() + 1) % 2 !== (n + 1) % 2) {
                    $('<tr class="stripe-pad" style="display: none;"></tr>').insertBefore(this);
                }
                n++;
            });
        });
    };
    // updates of the pipes, newest first; errors span the row
    function history_reload() {
        ajaxCall("/api/speedtest/shaper/history", {}, function(rows, status) {
            var body = $('#history_block').empty();
            var td = function(text) { return $('<td class="text-center"/>').text(text); };
            var pipe = function(r, dir) {
                var before = r[dir + ' before (Mbit/s)'], after = r[dir + ' after (Mbit/s)'];
                if (before === '') {
                    return td('');
                }
                // Kbit/s pipes (below 20 Mbit/s) to the Kbit, whole Mbit/s above
                var fmt = function(v) {
                    return parseFloat(v) < 20 ? parseFloat(v).toFixed(3).replace(/\.?0+$/, '') : parseFloat(v).toFixed(0);
                };
                // "kept (lower ...)", "raised, CoDel target 23 ms": the speed shows the action, the rest in brackets
                var note = r[dir].match(/^(\w+),? ?(.*)$/) || ['', r[dir], ''];
                var rest = note[2] === '' || /^\(.*\)$/.test(note[2]) ? note[2] : '(' + note[2] + ')';
                var cell = $('<td class="text-center"/>').append(
                    $('<b/>').text((before === after ? fmt(after) : fmt(before) + ' \u2192 ' + fmt(after)) + ' Mbit/s'));
                return rest === '' ? cell : cell.append($('<br/>'), $('<small/>').text(rest));
            };
            // runs taken from the system log have no best results
            var best = function(r, use) {
                return r[use + ' download (Mbit/s)'] === '' ? '' : parseFloat(r[use + ' download (Mbit/s)']).toFixed(2) +
                    ' / ' + parseFloat(r[use + ' upload (Mbit/s)']).toFixed(2);
            };
            $.each(Array.isArray(rows) ? rows : [], function(i, r) {
                var tr = $('<tr/>').append(td(r['time (UTC)'].replace(' ', 'T')));
                if (r.status === 'error') {
                    tr.append($('<td colspan="4" class="text-center text-danger"/>').text(r.message));
                } else {
                    var raise = best(r, 'raise');
                    tr.append(pipe(r, 'download'), pipe(r, 'upload'),
                        td(best(r, 'best') === '' ? '\u2013' : best(r, 'best') + (raise !== '' ? ' (' + raise + ')' : '')),
                        $('<td class="text-left"/>').text(r.basis));
                }
                body.append(tr);
            });
        });
    };
    // the server id field holds "id" or "(id) server name"; returns the id, '' when empty, null when invalid
    function serverid_value() {
        var m = $('#serverid').val().trim().match(/^(?:\((\d+)\).*|(\d+))?$/);
        return m ? (m[1] || m[2] || '') : null;
    };
    // pick a server of the list and show it in the server id field as "(id) server name"
    function serverid_select(id) {
        var option = $('#speedlist option').filter(function() { return $(this).val() === id; });
        $('#speedlist').val(id);
        $('#serverid').val(id === '' ? '' : "(" + id + ") " + option.data('name'));
        $('#serverid_error').hide();
    };
    function serverlist_reload() {
        $("#serverlistAct_progress").addClass("fa fa-spinner fa-pulse");
        ajaxCall(url = "/api/speedtest/service/serverlist", sendData = {}, callback = function(l, status) {
            $("#serverlistAct_progress").removeClass("fa fa-spinner fa-pulse");
            var selected = serverid_value();
            $('#speedlist').empty().append($('<option/>').val("").text("{{ lang._('automatic (nearest server)') }}"));
            if (Array.isArray(l) && l.length > 0) {
                for (var i = 0; i < l.length; i++) {
                    $('#speedlist').append($('<option/>').val(l[i].id).data('name', l[i].name)
                        .text("(" + l[i].id + ") " + l[i].name + ", " + l[i].location));
                }
                // keep an entered id when it is part of the fetched list, else take the nearest server (listed first)
                var found = selected && $('#speedlist option').filter(function() { return $(this).val() === selected; }).length > 0;
                serverid_select(found ? selected : String(l[0].id));
            } else {
                $('#speedlist').append($('<option/>').val("").prop("disabled", true)
                    .text(l && l.error ? l.error : "{{ lang._('no servers returned') }}"));
            }
        });
    };
    // core HTML-escapes <, > and & in API replies (shown as text here, so undo it)
    function api_text(text) {
        return String(text).replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&amp;/g, '&');
    };
    // the speedtest module row: what is installed, and the button to install or replace it
    function version_reload() {
        ajaxCall(url = "/api/speedtest/service/version", sendData = {}, callback = function(l, status) {
            var text, error = false, button = '';
            if (!l || (!l.version && !l.error)) {
                text = "{{ lang._('No response') }}";
                error = true;
            } else if (l.error) {
                text = api_text(l.error);
                error = true;
                button = "{{ lang._('Reinstall Ookla') }}";
            } else if (l.version == 'none') {
                text = "{{ lang._('Not installed') }}";
                error = true;
                button = "{{ lang._('Install Ookla') }}";
            } else if (l.version == 'cli') {
                text = l.message + " {{ lang._('(no longer maintained)') }}";
                button = "{{ lang._('Switch to Ookla') }}";
            } else {
                text = l.message;
            }
            if (button !== '' && l && l.supported === false) {
                text += " ({{ lang._('Ookla provides FreeBSD builds for x86_64 only') }})";
                button = '';
            }
            $('#module_status').text(text).toggleClass('text-danger', error);
            $('#moduleInstallAct_label').text(button);
            $('#moduleInstallAct').toggle(button !== '');
            // tests need a module; speedtest-cli still works until it is replaced
            $('.canruntests').toggle(!!l && (l.version == 'binary' || l.version == 'cli'));
            speedtest_stripes();
        });
    };

    // run a speedtest (serverid empty: nearest server) and show its result
    function run_speedtest(serverid, btn) {
        $("#" + btn + "_progress").addClass("fa fa-spinner fa-pulse");
        ajaxCall(url = "/api/speedtest/service/run/" + (serverid === '' ? '0' : serverid), sendData = {}, callback = function(r, status) {
            $("#" + btn + "_progress").removeClass("fa fa-spinner fa-pulse");
            $("#test_results").show();
            if (r.error) {
                $("#dlspeed").text(r.error);
                $("#ulspeed").text("");
                $("#latency").text("");
                $("#ISP1").text("");
                $("#ISP2").text("");
                $("#ISP3").text("");
                $("#client").text("");
                $("#result").text("");
            } else {
                $("#dlspeed").text(r.download + " Mbps");
                $("#ulspeed").text(r.upload + " Mbps");
                $("#latency").text(r.latency + " ms");
                $("#ISP1").text("id: " + r.serverid);
                $("#ISP2").text(r.servername);
                $("#ISP3").text(r.country);
                $("#client").text(r.clientip);
                if (r.link) {
                    $("#result").empty().append($('<a target="_blank"/>').attr('href', r.link).text(r.link));
                } else {
                    $("#result").text("{{ lang._('not shared') }}");
                }
            }
            stat_reload();
            log_reload();
        });
    };
    // MSS clamping of the saved shaper interface; the button only shows when it is missing
    function mss_reload() {
        ajaxGet("/api/speedtest/shaper/mss", {}, function(r, status) {
            var missing = r && r.status == 'missing';
            $('#mss_status').toggleClass('text-danger', missing)
                .val(r && r.message ? r.message : "{{ lang._('No response') }}");
            $('#mssSetAct').toggle(missing);
        });
    };
    // servers the scheduled speedtests use, best ranked first
    function servers_reload() {
        ajaxGet("/api/speedtest/service/servers", {}, function(r, status) {
            var text = "{{ lang._('None ranked yet, speedtest picks the server') }}";
            if (r && r.servers) {
                var names = $.map(r.candidates || [], function(s) {
                    return '(' + s.id + ') ' + api_text(s.name) + (s.score !== null ? ' ' + Math.round(s.score * 100) + '%' : '');
                });
                if (names.length) {
                    text = names.join('; ');
                }
                if (r.blocked && r.blocked.length) {
                    text += '; ' + "{{ lang._('blocked until tomorrow') }}" + ': ' + $.map(r.blocked, api_text).join(', ');
                }
            } else if (r && r.error) {
                text = api_text(r.error);
            }
            $('#scheduled_servers').val(text);
        });
    };
    // help on the page (server fields, schedule, shaper form, MSS row), shown or hidden together;
    // follows core's "full help" preset of the session, which core already applied to the forms
    function page_help(on, store) {
        $("#toggle_help_page").toggleClass("fa-toggle-on", on).toggleClass("fa-toggle-off", !on)
            .toggleClass("text-success", on).toggleClass("text-danger", !on);
        $('#frm_shaper [data-for^="help_for"], #frm_schedule [data-for^="help_for"], .speedtest-help')
            .toggleClass('hidden', !on).toggleClass('show', on);
        if (store) {
            try {
                sessionStorage.setItem('all_help_preset', on ? 1 : 0);
            } catch (e) {
                // no session storage: the setting only lasts for this page
            }
        }
    };
    function help_preset() {
        try {
            return sessionStorage.getItem('all_help_preset') === "1";
        } catch (e) {
            return false;
        }
    };
    function shaper_result(r) {
        var text = (r && r.message) ? r.message : "{{ lang._('No response') }}";
        var cls = (r && (r.status == 'error' || r.status == 'disabled')) ? 'text-danger' : 'text-success';
        $('#shaper_result').empty().append($('<span/>').addClass(cls).text(text));
    };
    // save the shaper settings first, then run the given action
    // "Enable traffic shaper" as last saved; null until the settings are loaded
    var shaper_saved_enabled = null;
    function shaper_enabled() {
        return $('[id="speedtest.shaper.enabled"]').is(':checked');
    };
    // Create shaper and Apply now need the shaper enabled; Save stays usable until the
    // unticked state is saved, otherwise the shaper could not be switched off
    function shaper_buttons() {
        var on = shaper_enabled();
        $('#shaperCreateAct, #shaperApplyAct').prop('disabled', !on);
        $('#shaperSaveAct').prop('disabled', !on && shaper_saved_enabled === false);
    };
    function shaper_action(btn, url) {
        $("#" + btn + "_progress").addClass("fa fa-spinner fa-pulse");
        saveFormToEndpoint("/api/speedtest/shaper/set", 'frm_shaper', function() {
            shaper_saved_enabled = shaper_enabled();
            shaper_buttons();
            ajaxCall(url, {}, function(r, status) {
                $("#" + btn + "_progress").removeClass("fa fa-spinner fa-pulse");
                shaper_result(r);
                history_reload();
            });
        }, true, function() {
            $("#" + btn + "_progress").removeClass("fa fa-spinner fa-pulse");
        });
    };

    $(document).ready(function() {
        // run on doc load
        version_reload();
        stat_reload();
        log_reload();
        // the shaper form has no info icons or "full help" switch, its help follows the page's help slider
        $('#frm_shaper .control-label a.showhelp, #frm_shaper .control-label i.fa-info-circle').remove();
        $('#frm_schedule .control-label a.showhelp, #frm_schedule .control-label i.fa-info-circle').remove();
        $('#show_all_help_frm_shaper, #show_all_help_frm_schedule').closest('tr').remove();
        // "Create shaper" next to the interface it creates the shaper on, in the column of "run speedtest"
        $('[id="row_speedtest.shaper.interface"] > td:last').prepend($('#shaperCreateAct'));
        // MSS clamping status (not a setting of its own) below the WAN type, button in the same column
        $('[id="row_speedtest.shaper.dsltype"]').after($('<tr id="row_mss"/>')
            .append($('<td/>').append($('<div class="control-label"/>').append($('<b/>').text("{{ lang._('MSS clamping') }}"))))
            // read-only text box, like the other fields of the form
            .append($('<td/>').append($('<input type="text" id="mss_status" class="form-control" size="50" readonly="readonly"/>')
                    .attr('aria-label', "{{ lang._('MSS clamping') }}"))
                .append($('<div class="hidden" data-for="help_for_mss"/>').append($('<small/>')
                    .text("{{ lang._('The WAN interface clamps TCP to its MTU minus 40, needed when the MTU is below 1500 (PPPoE). Set MSS clamping sets the MSS of the WAN interface to its MTU.') }}"))))
            .append($('<td/>').append($('#mssSetAct'))));
        mss_reload();
        // servers of the scheduled speedtests (not a setting) below the last schedule setting
        $('[id="row_speedtest.shaper.multiple"]').after($('<tr id="row_scheduled_servers"/>')
            .append($('<td/>').append($('<div class="control-label"/>').append($('<b/>').text("{{ lang._('Scheduled servers') }}"))))
            .append($('<td/>').append($('<input type="text" id="scheduled_servers" class="form-control" size="50" readonly="readonly"/>')
                    .attr('aria-label', "{{ lang._('Scheduled servers') }}"))
                .append($('<div class="hidden" data-for="help_for_scheduled_servers"/>').append($('<small/>')
                    .text("{{ lang._('Ranked by their results of the last 30 days, as a share of the fastest result of the same day. Each night starts with Get server list; each test of an interval uses another region (a server of a provider in one location), the best ranked on the list. A region that fails 4 times (retried after 15, 30 and 60 seconds) is blocked until the next day, a second failing region of the same provider blocks all its regions; the test moves on to the next region in the order of the list. Once a night a server of the list without results gets a trial.') }}"))))
            .append($('<td/>')));
        servers_reload();
        // read-only boxes in the colour of the editable ones (the theme greys out read-only inputs);
        // the text colour stays with the classes, MSS "missing" is red
        $('#mss_status, #scheduled_servers').css('background-color', $('[id="speedtest.shaper.days"]').css('background-color'));
        page_help(help_preset(), false);
        mapDataToFormUI({'frm_shaper': "/api/speedtest/shaper/get", 'frm_schedule': "/api/speedtest/shaper/get"}).done(function() {
            $('.selectpicker').selectpicker('refresh');
            shaper_saved_enabled = shaper_enabled();
            shaper_buttons();
        });
        $('[id="speedtest.shaper.enabled"]').change(shaper_buttons);

    });
    $(function() {
        // the help slider shows/hides all help on the page and stores it like core's "full help" switch
        $("#toggle_help_page").click(function() {
            page_help(!$(this).hasClass("fa-toggle-on"), true);
        });
        // show/hide the speedtest log and the pipe changes; core's advanced mode toggle only handles
        // elements inside a form
        $(".log-toggle").click(function(e) {
            e.preventDefault();
            var icon = $(this).find('i');
            icon.toggleClass("fa-toggle-on fa-toggle-off").toggleClass("text-success text-danger");
            $('.' + $(this).data('rows')).toggle(icon.hasClass("fa-toggle-on"));
            if ($(this).data('rows') === 'shaper-log' && icon.hasClass("fa-toggle-on")) {
                history_reload();
            }
        });
        $("#moduleInstallAct").click(function() {
            stdDialogConfirm(
                $('#moduleInstallAct_label').text(),
                "{{ lang._('Install the Ookla speedtest CLI from install.speedtest.net (replacing speedtest-cli if installed)?') }}",
                "{{ lang._('Yes') }}", "{{ lang._('Cancel') }}", function() {
                    $("#moduleInstallAct_progress").addClass("fa fa-spinner fa-pulse");
                    $("#moduleInstallAct").prop('disabled', true);
                    ajaxCall("/api/speedtest/service/installsocket", {}, function(r, status) {
                        $("#moduleInstallAct_progress").removeClass("fa fa-spinner fa-pulse");
                        $("#moduleInstallAct").prop('disabled', false);
                        $('#module_output').text(r && r.output ? api_text(r.output) : "{{ lang._('No response') }}");
                        $('#module_output_row').show();
                        speedtest_stripes();
                        version_reload();
                    });
                });
        });
        // reload the page, which also clears the install output
        $("#moduleRefreshAct").click(function() {
            window.location.reload();
        });
        // fetch the list of nearest servers on demand
        $("#serverlistAct").click(function() {
            serverlist_reload();
        });
        // picking a server from the list fills the (optional) server id field
        $("#speedlist").change(function() {
            serverid_select($(this).val());
        });
        $("#reportAct").click(function() {
            var serverid = serverid_value();
            if (serverid === null) {
                $('#serverid_error').text("{{ lang._('Please enter a numeric server id or leave the field empty.') }}").show();
                return;
            }
            $('#serverid_error').hide();
            run_speedtest(serverid, 'reportAct');
        });
        $("#shaperSaveAct").click(function() {
            $("#shaperSaveAct_progress").addClass("fa fa-spinner fa-pulse");
            saveFormToEndpoint("/api/speedtest/shaper/set", 'frm_shaper', function() {
                $("#shaperSaveAct_progress").removeClass("fa fa-spinner fa-pulse");
                shaper_saved_enabled = shaper_enabled();
                shaper_buttons();
                mss_reload();
            }, false, function() {
                $("#shaperSaveAct_progress").removeClass("fa fa-spinner fa-pulse");
            });
        });
        // Save only stores the schedule, Apply now also puts it in cron (it never runs a speedtest)
        $("#scheduleSaveAct").click(function() {
            $("#scheduleSaveAct_progress").addClass("fa fa-spinner fa-pulse");
            saveFormToEndpoint("/api/speedtest/shaper/set", 'frm_schedule', function() {
                $("#scheduleSaveAct_progress").removeClass("fa fa-spinner fa-pulse");
            }, false, function() {
                $("#scheduleSaveAct_progress").removeClass("fa fa-spinner fa-pulse");
            });
        });
        $("#scheduleApplyAct").click(function() {
            $("#scheduleApplyAct_progress").addClass("fa fa-spinner fa-pulse");
            saveFormToEndpoint("/api/speedtest/shaper/set", 'frm_schedule', function() {
                ajaxCall("/api/speedtest/shaper/schedule", {}, function(r, status) {
                    $("#scheduleApplyAct_progress").removeClass("fa fa-spinner fa-pulse");
                    var ok = r && r.status == 'ok';
                    $('#schedule_result').empty().append($('<span/>').addClass(ok ? 'text-success' : 'text-danger')
                        .text(r && r.message ? r.message : "{{ lang._('No response') }}"));
                });
            }, true, function() {
                $("#scheduleApplyAct_progress").removeClass("fa fa-spinner fa-pulse");
            });
        });
        $("#shaperApplyAct").click(function() {
            shaper_action('shaperApplyAct', "/api/speedtest/shaper/apply");
        });
        $("#shaperCreateAct").click(function() {
            stdDialogConfirm(
                "{{ lang._('Create shaper') }}",
                "{{ lang._('Create the WAN_download_p and WAN_upload_p pipes, their queues and rules on the selected interface for each direction that has none? The rules exclude the interface address, so traffic of the firewall itself (and the speedtest) is not shaped.') }}",
                "{{ lang._('Yes') }}", "{{ lang._('Cancel') }}", function() {
                    shaper_action('shaperCreateAct', "/api/speedtest/shaper/create");
                });
        });
        $("#mssSetAct").click(function() {
            stdDialogConfirm(
                "{{ lang._('Set MSS clamping') }}",
                "{{ lang._('Set the MSS of the WAN interface to its MTU, so the firewall clamps TCP to the MTU minus 40, and reload the firewall rules?') }}",
                "{{ lang._('Yes') }}", "{{ lang._('Cancel') }}", function() {
                    $("#mssSetAct_progress").addClass("fa fa-spinner fa-pulse");
                    ajaxCall("/api/speedtest/shaper/setmss", {}, function(r, status) {
                        $("#mssSetAct_progress").removeClass("fa fa-spinner fa-pulse");
                        shaper_result(r);
                        mss_reload();
                    });
                });
        });
        // Delete Log
        $("#deletelogAct").click(function() {
            $("#deletelogAct_progress").addClass("fa fa-spinner fa-pulse");
            ajaxCall(url = "/api/speedtest/service/deletelog/", sendData = {}, callback = function(data, status) {
                stat_reload();
                log_reload();
                $("#deletelogAct_progress").removeClass("fa fa-spinner fa-pulse");
            });
            $('#log_block').html("");
            log_reload();
        });
        $("#clearhistoryAct").click(function() {
            stdDialogConfirm(
                "{{ lang._('Clear') }}",
                "{{ lang._('Clear the list of pipe changes? It is not filled from the system log again.') }}",
                "{{ lang._('Yes') }}", "{{ lang._('Cancel') }}", function() {
                    $("#clearhistoryAct_progress").addClass("fa fa-spinner fa-pulse");
                    ajaxCall("/api/speedtest/shaper/clearhistory", {}, function(r, status) {
                        $("#clearhistoryAct_progress").removeClass("fa fa-spinner fa-pulse");
                        history_reload();
                    });
                });
        });
    });

</script>

