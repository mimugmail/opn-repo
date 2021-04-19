<?php

/*
 * Copyright (C) 2014-2016 Deciso B.V.
 * Copyright (C) 2008 Seth Mos <seth.mos@dds.nl>
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

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $pconfig = array();
    $pconfig['ipcheckfilter'] = !empty($config['widgets']['ipcheckfilter']) ? explode(',', $config['widgets']['ipcheckfilter']) : array();
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $pconfig = $_POST;
    if (!empty($pconfig['ipcheckfilter'])) {
        $config['widgets']['ipcheckfilter'] = implode(',', $pconfig['ipcheckfilter']);
    } elseif (isset($config['widgets']['ipcheckfilter'])) {
        unset($config['widgets']['ipcheckfilter']);
    }
    write_config("Saved IPcheck Filters via Dashboard");
    header(url_safe('Location: /index.php'));
    exit;
}
$options = ["address" => "IP address", 
            "isp" => "Internet provider", 
            "vpn" => "VPN/Proxy/TOR",
            "risk"=>"Risk score"];
?>

<script>
    $(window).on("load", function() {
        function fetch_ipcheck(){
          if ($("#ipcheckfilter").val().includes('address')) {$('#rowaddress').removeClass("hidden")}
          if ($("#ipcheckfilter").val().includes('isp')) {$('#rowisp').removeClass("hidden")}
          if ($("#ipcheckfilter").val().includes('vpn')) {$('#rowvpn').removeClass("hidden")}
          if ($("#ipcheckfilter").val().includes('risk')) {$('#rowrisk').removeClass("hidden")}
          ajaxGet('/api/ipcheck/run/status', {}, function(r, status) {
            $('#rowhdr').html('<small>'+r.timestamp+'</small>')
            if(r.ipv4.ip) {
              $('#ipv4hdr,#ipv4address,#ipv4isp,#ipv4vpn,#ipv4risk').removeClass("hidden")
              $('#ipv4address').html(r.ipv4.ip+'<small>'+'<br/>'+s(r.ipv4.network)+'<br/>'+s(r.ipv4.network_type)+'</small>')
              $('#ipv4isp').html(s(r.ipv4.isp)+'<small><br/>'+s(r.ipv4.asn)+'<br/>'+s(r.ipv4.city)+'<br/>'+s(r.ipv4.region)+'<br/>'+s(r.ipv4.country)+'</small>');
              proxy = r.ipv4.proxy==true?'<span class="label label-danger">True</span>':'<span class="label label-success">False</span>'
              vpn = r.ipv4.vpn==true?'<span class="label label-danger">True</span>':'<span class="label label-success">False</span>'
              tor = r.ipv4.tor==true?'<span class="label label-danger">True</span>':'<span class="label label-success">False</span>'
              $('#ipv4vpn').html(proxy+'<br/>'+vpn+'<br/>'+tor)
              $('#ipv4risk').html('<small>'+s(r.ipv4.ipqs_fraud_score)+'<br/>'+s(r.ipv4.proxycheck_risk)+'</small>')
              }
              if(r.ipv6.ip) {
              $('#ipv6hdr,#ipv6address,#ipv6isp,#ipv6vpn,#ipv6risk').removeClass("hidden")
              $('#ipv6address').html(r.ipv6.ip+'<small>'+'<br/>'+s(r.ipv6.network)+'<br/>'+s(r.ipv6.network_type)+'</small>')
              $('#ipv6isp').html(s(r.ipv6.isp)+'<small><br/>'+s(r.ipv6.asn)+'<br/>'+s(r.ipv6.city)+'<br/>'+s(r.ipv6.region)+'<br/>'+s(r.ipv6.country)+'</small>');
              proxy = r.ipv6.proxy==true?'<span class="label label-danger">True</span>':'<span class="label label-success">False</span>'
              vpn = r.ipv6.vpn==true?'<span class="label label-danger">True</span>':'<span class="label label-success">False</span>'
              tor = r.ipv6.tor==true?'<span class="label label-danger">True</span>':'<span class="label label-success">False</span>'
              $('#ipv6vpn').html(proxy+'<br/>'+vpn+'<br/>'+tor)
              $('#ipv6risk').html('<small>'+s(r.ipv6.ipqs_fraud_score)+'<br/>'+s(r.ipv6.proxycheck_risk)+'</small>')
              }
            });
          setTimeout(fetch_ipcheck, 5000);
        }
        fetch_ipcheck();
    });

    function s(i) {
        return (i===false || i===null)?'':i
    }
</script>

<div id="ipcheck-settings" class="widgetconfigdiv" style="display:none;">
  <form action="/widgets/widgets/ipcheck.widget.php" method="post" name="iformd">
    <table class="table table-condensed">
      <tr>
        <td>
          <select id="ipcheckfilter" name="ipcheckfilter[]" multiple="multiple" class="selectpicker_widget">
          <?php foreach (array_keys($options) as $ipsetting): ?>
            <option value="<?= html_safe($ipsetting) ?>" <?= in_array($ipsetting, $pconfig['ipcheckfilter']) ? 'selected="selected"' : '' ?>><?= html_safe($ipsetting) ?></option>
          <?php endforeach;?>            
          </select>
          <button id="submitd" name="submitd" type="submit" class="btn btn-primary" value="yes"><?= gettext('Save') ?></button>
        </td>
      </tr>
    </table>
  </form>
</div>

<!-- gateway table -->
<table id="ipconfig_widget_table" class="table table-striped table-condensed">
    <tr>
        <td id="rowhdr">timestamp</td>
        <td id="ipv4hdr" class="hidden">IPv4</td>
        <td id="ipv6hdr" class="hidden">IPv6</td>
    </tr>
    <tr id="rowaddress" class="hidden">
        <td>Public IP address:<small><br/>Network:<br/>Network type:</small></td>
        <td id="ipv4address" class="hidden"></td>
        <td id="ipv6address" class="hidden"></td>
    </tr>
    <tr id="rowisp" class="hidden">
        <td>Internet provider:<small><br/>ASN:<br/>City:<br/>Region:<br/>Country:</small></td>
        <td id="ipv4isp" class="hidden"></td>
        <td id="ipv6isp" class="hidden"></td>
    </tr>
    <tr id="rowvpn" class="hidden">
        <td><small> Proxy detected:<br/>VPN detected:<br/>TOR detected:</small></td>
        <td id="ipv4vpn" class="hidden"></td>
        <td id="ipv6vpn" class="hidden"></td>
    </tr>
    <tr id="rowrisk" class="hidden">
        <td><small>IPQS Fraud score:<br/>Proxy risk score:</small></td>
        <td id="ipv4risk" class="hidden"></td>
        <td id="ipv6risk" class="hidden"></td>
    </tr> 
</table>

<!-- needed to display the widget settings menu -->
<script>
//<![CDATA[
  $("#ipcheck-configure").removeClass("disabled");
//]]>
</script>
