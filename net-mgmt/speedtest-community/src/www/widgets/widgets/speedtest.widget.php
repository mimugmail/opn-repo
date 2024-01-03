
<?php


/*
 * Copyright (C) 2021 Miha Kralj
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

require_once("guiconfig.inc");
?>
<script>
    $(document).ready(function() {
        ajaxGet("/api/speedtest/service/showstat", {}, function(l,status) {
            $('#stat_latency').html("<b>"+l.latency.avg+" ms<\/b><small> (min: "+l.latency.min+" ms, max: "+l.latency.max +" ms)</small>")
            $('#stat_download').html("<b>"+l.download.avg+" Mbps<\/b><small> (min: "+l.download.min+" Mbps, max: "+l.download.max +" Mbps)</small>")
            $('#stat_upload').html("<b>"+l.upload.avg+" Mbps<\/b><small> (min: "+l.upload.min+" Mbps, max: "+l.upload.max +" Mbps)</small>")
        });

        ajaxGet("/api/speedtest/service/showlog", {}, function(l,status) {
            for (var i = 0; i < 6; i++) {
                var obj = obj +
                    "<tr><td class=\"text-left\" style=\"\">" + l[i][0] + "</td>" +
                    "<td class=\"text-left\" style=\"\">" + parseFloat(l[i][5]).toFixed(2) + "</td>" +
                    "<td class=\"text-left\" style=\"\">" + parseFloat(l[i][6]).toFixed(2) + "</td>" +
                    "<td class=\"text-left\" style=\"\">" + parseFloat(l[i][7]).toFixed(2) + "</td></tr>"
            }
            $('#log_block').html(obj);
        });
    });
</script>
<!-- gateway table -->
<table id="speedtest_widget_table" class="table table-striped table-condensed">
  <tr><td style="width:25%">Avg Download:</td><td><div id="stat_download">0 Mbps (min: 0 Mbps, max: 0 Mbps)</div></td></tr>
  <tr><td>Avg Upload:</td><td><div id="stat_upload">0 Mbps (min: 0 Mbps, max: 0 Mbps)</div></td></tr>
  <tr><td>Avg Latency:</td><td><div id="stat_latency">0.00 ms (min: 0.00 ms, max: 0.00 ms)</div></td></tr>
</table>
<table>
<thead>
<tr id="log_head" data-advanced="true" ">
    <th data-column-id="Timestamp" class="text-left" style="width:7em;">Timestamp (Local)</th>
    <th data-column-id="Latency" class="text-left" style="width:2em;">Download</th>
    <th data-column-id="DlSpeed" class="text-left" style="width:3em;">Upload</th>
    <th data-column-id="UlSpeed" class="text-left" style="width:3em;">Latency</th>
</tr>
</thead>
<tbody id="log_block" data-advanced="true" ">
</table>
