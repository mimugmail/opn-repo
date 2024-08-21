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
<div class="content-box">
    <table class="table table-condensed">
        <tbody>
            <tr>
                <td>
                    <h2 style="margin-top:1ex;">Statistics</h2>
                </td>
                <td style="width: 78%; text-align: right; background-color: inherit; border-top-width: 0px;">
                    <small>help </small>
                    <i class="fa fa-toggle-off text-success" style="cursor: pointer;" id="show_all_help_page"></i>
                </td>
            </tr>
            <tr>
                <td style="width:30%">Speedtest probes:</td>
                <td>
                    <div id="stat_samples">0</div>
                </td>
            </tr>
            <tr>
                <td>Average Download speed:</td>
                <td>
                    <div id="stat_download">0 Mbps (min: 0 Mbps, max: 0 Mbps)</div>
                </td>
            </tr>
            <tr>
                <td>Average Upload speed:</td>
                <td>
                    <div id="stat_upload">0 Mbps (min: 0 Mbps, max: 0 Mbps)</div>
                </td>
            </tr>
            <tr>
                <td>Average Latency:</td>
                <td>
                    <div id="stat_latency">0.00 ms (min: 0.00 ms, max: 0.00 ms)</div>
                </td>
            </tr>
        </tbody>
    </table>
</div>
<h2>Run speedtest</h2>
<div class="content-box">
    <div class="content-box-main collapse in" id="system_information-container" style="display:inline">
        <table class="table table-condensed">
            <thead>
                <tr id="canruntests" style="display:none">
                    <td style="width:35%">
                        <select id="speedlist" name="serverid">
                        <option value="0">Fetching available Speedtest servers...</option>
                        /select>
                    </td>
                    <td ><button class="btn btn-primary" id="reportAct" type="button">
                <b>{{ lang._('run speedtest') }}</b> <i id="reportAct_progress"></i></button></td>
                </tr>
                <tr>
                    <div id="checkingspeedtest">&nbsp;&nbsp;Locating speedtest module...</div>
                    <div id="nospeedtest" style="display:none">&nbsp;&nbsp;No installed speedtest modules found. Install 
                        <button class="btn btn-xs btn-primary" id="cliAct" type="button"><b>speedtest-cli</b><i id="cliAct_progress"></i></button>
                    or 
                        <button class="btn btn-xs btn-primary" id="binAct" type="button"><b>Ookla</b><i id="binAct_progress"></i></button>
                    </div>
                </tr>
            </thead>
            <tbody id="test_results" style="display:none">
                <tr>
                    <td>Download speed</td>
                    <td id="dlspeed">0 Mbps</td>
                </tr>
                <tr>
                    <td>Upload speed</td>
                    <td id="ulspeed">0 Mbps</td>
                </tr>
                <tr>
                    <td>Latency (ping)</td>
                    <td id="latency">0 ms</td>
                </tr>
                <tr>
                    <td>Speedtest server</td>
                    <td>
                        <div id="ISP1"></div>
                        <div id="ISP2"></div>
                        <div id="ISP3"></div>
                    </td>
                </tr>
                <tr>
                    <td>Client IP:</td>
                    <td>
                        <div id="client"></div>
                    </td>
                </tr>
                <tr>
                    <td>Result id</td>
                    <td>
                        <div id="result"></div>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>
</div>
<small><div id="version"></div></small>
<div class="hide" data-for="help_for_speedprobes">

    <a href="/ui/cron"><button class="btn btn-xs btn-primary" id="cronAct" type="button">
            <b> schedule in cron </b>
    </button></a>
    <button id="cli1Act" class="btn btn-xs" type="button">
        <b>switch to http speedtest</b>
    </button>
    <button id="bin1Act" class="btn btn-xs" type="button">
        <b>switch to socket speedtest</b>
    </button><br>

</div>

<div class="content-box" id="logs">
    <table id="grid-log" class="table table-condensed">
        <thead>
            <tr>
                <th style="text-align:left">
                    <a href="#"><i class="fa fa-toggle-off text-danger" id="show_advanced_log"></i></a>
                    <small id="togglelog">show log</small>
                </th>
            </tr>
            <tr><th>
                <div id="exportlog_button" data-advanced="true" style="display: none;">
                    <a href="/api/speedtest/download/csv">
                        <button class="btn btn-sm btn-primary" id="downloadAct" type="button">
                            <b>Export log</b>
                        </button>
                    </a>
                </div>
            </th>
            <th>
                <div id="clearlog_button" data-advanced="true" style="display: none;">
                    <button class="btn  btn-sm btn-primary" id="deletelogAct" type="button">
                        <b>{{ lang._('Clear log') }}</b> <i id="deletelogAct_progress"></i></button>
                </div>
            </th></tr>
            <tr id="log_head" data-advanced="true" style="display: none;">
                <th data-column-id="Timestamp" class="text-left" style="width:7em;">Timestamp (Local)</th>
                <th data-column-id="ServerId" class="text-left" style="width:3em;">Server id</th>
                <th data-column-id="ServerName" class="text-left" style="width:12em;">Server name</th>
                <th data-column-id="Latency" class="text-left" style="width:2em;">Download</th>
                <th data-column-id="DlSpeed" class="text-left" style="width:3em;">Upload</th>
                <th data-column-id="UlSpeed" class="text-left" style="width:3em;">Latency</th>
            </tr>
        </thead>
        <tbody id="log_block" data-advanced="true" style="display: none;">
        </tbody>
    </table>
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
            for (var i = 0; i < l.length; i++) {
                var obj = obj +
                    "<tr><td class=\"text-left\" style=\"\">" + l[i][0] + "</td>" +
                    "<td class=\"text-left\" style=\"\">" + l[i][2] + "</td>" +
                    "<td class=\"text-left\" style=\"\">" + l[i][3] + "</td>" +
                    "<td class=\"text-left\" style=\"\">" + parseFloat(l[i][5]).toFixed(2) + "</td>" +
                    "<td class=\"text-left\" style=\"\">" + parseFloat(l[i][6]).toFixed(2) + "</td>" +
                    "<td class=\"text-left\" style=\"\">" + parseFloat(l[i][7]).toFixed(2) + "</td></tr>"
            }
            $('#log_block').html(obj);
        });
    };
    function version_reload() {
        ajaxCall(url = "/api/speedtest/service/version", sendData = {}, callback = function(l, status) {
            $('#checkingspeedtest').hide();
            if (l.version=='none') {
                $('#nospeedtest').show("div");
            } else {
                $('#canruntests').show();
                $('#version').text(l.message);
                if (l.version=='binary') {
                    $('#bin1Act').addClass('btn-success disabled')
                    $('#bin1Act').removeClass('btn-primary')
                    $('#cli1Act').removeClass('btn-success disabled')
                    $('#cli1Act').addClass('btn-primary')
                } else {
                    $('#cli1Act').addClass('btn-success disabled')
                    $('#cli1Act').removeClass('btn-primary')
                    $('#bin1Act').removeClass('btn-success disabled')
                    $('#bin1Act').addClass('btn-primary')
                }
                
                ajaxCall(url = "/api/speedtest/service/serverlist", sendData = {}, callback = function(l, status) {
                    $('#speedlist').text("")
                    for (var i = 0; i < l.length; i++) {
                        $('#speedlist').append("<option value=\"" + l[i].id + "\">" + "(" + l[i].id + ") " + l[i].name + ", " + l[i].location + "<\/option>");
                    }
                });
            }
            });
    };

    $(document).ready(function() {
        // run on doc load
        version_reload();
        stat_reload();
        log_reload();

    });
    $(function() {
        // pressing button
        $("#cliAct").click(function() {
            ajaxCall(url = "/api/speedtest/service/installhttp/", sendData = {}, callback = function(r, status) {
                version_reload();
                $('#nospeedtest').hide();
                $('#canruntests').show();
            });
        });
        $("#binAct").click(function() {
            ajaxCall(url = "/api/speedtest/service/installsocket/", sendData = {}, callback = function(r, status) {
                version_reload();
                $('#nospeedtest').hide();
                $('#canruntests').show();
            });
        });
        $("#cli1Act").click(function() {
            ajaxCall(url = "/api/speedtest/service/installhttp/", sendData = {}, callback = function(r, status) {
                version_reload();
                $('#nospeedtest').hide();
                $('#canruntests').show();
            });
        });
        $("#bin1Act").click(function() {
            ajaxCall(url = "/api/speedtest/service/installsocket/", sendData = {}, callback = function(r, status) {
                version_reload();
                $('#nospeedtest').hide();
                $('#canruntests').show();
            });
        });
        $("#reportAct").click(function() {
            $("#reportAct_progress").addClass("fa fa-spinner fa-pulse");
            ajaxCall(url = "/api/speedtest/service/run/" + $('#speedlist').val(), sendData = {}, callback = function(r, status) {
                $("#reportAct_progress").removeClass("fa fa-spinner fa-pulse");
                $("#test_results").attr("style", "display:content");
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
                    $("#result").html("<a href=\"" + r.link + "\"  target=\"_blank\">" + r.link + "</a>");
                }
                stat_reload();
                log_reload();
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
    });

</script>

