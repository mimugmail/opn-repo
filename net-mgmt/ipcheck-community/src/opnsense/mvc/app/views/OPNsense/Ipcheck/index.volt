{#

OPNsense® is Copyright © 2014 – 2018 by Deciso B.V.
This file is Copyright © 2018 by Michael Muenz <m.muenz@gmail.com>
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1.  Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.

2.  Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

#}
Active APIs:<br/>
<span id="checkvpnapi" class="label">Vpnapi</span> 
<span id="checkproxy" class="label">Proxycheck</span>
<span id="checkip2loc" class="label">ip2location</span> 
<span id="checkip2proxy" class="label">ip2proxy</span> 
<span id="checkonionoo" class="label">Onionoo</span> 
<span id="checkipqs" class="label">IpQualityScore</span> 

<br/><br/>

<button class="btn btn-primary" id="runAct" type="button">
    <b>{{ lang._('call APIs') }}</b> <i id="runAct_progress"></i></button>


<table id="ipcheck_widget_table" class="table table-striped table-condensed">
    <tr>
        <td id="rowhdr"></td>
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
    <tr>
        <td style="text-align:left">
            <a href="#"><i class="fa fa-toggle-off text-danger" id="show_advanced"></i></a>
            <small>API details</small>
        </td>
    </tr>
    <tr id="advanced" class="hidden">
        <td>json dump:</td>
        <td id="ipv4json"></td>
        <td id="ipv6json"></td>
    </tr>
  </table>


<script>
    $(document).ready(function() {
        ajaxCall(url = "/api/ipcheck/run/list", {}, function(chck, status) {
            $('#checkvpnapi').addClass((chck.vpnapi==true)?'label-success':'label-default')
            $('#checkproxy').addClass((chck.proxycheck==true)?"label-success":"label-default")
            $('#checkip2loc').addClass((chck.ip2loc==true)?"label-success":"label-default")
            $('#checkip2proxy').addClass((chck.ip2proxy==true)?"label-success":"label-default") 
            $('#checkipqs').addClass((chck.ipqs==true)?"label-success":"label-default")
            $('#checkonionoo').addClass((chck.onionoo==true)?"label-success":"label-default")
        });
        ajaxCall(url = "/api/ipcheck/run/status", {}, function(chck, status) {
            render(chck);
        });
    });

    $(function() {
        $("#runAct").click(function() {
            $("#runAct_progress").addClass("fa fa-spinner fa-pulse");
            ajaxCall(url = "/api/ipcheck/run/all", {}, function(r, status) {
                $("#runAct_progress").removeClass("fa fa-spinner fa-pulse");
                render(r)
            });
        });
    });
    
    function s(i) {
        return (i===false || i===null)?'':i
    }
    function render(r){
        $('#rowaddress').removeClass("hidden")
        $('#rowisp').removeClass("hidden")
        $('#rowvpn').removeClass("hidden")
        $('#rowrisk').removeClass("hidden")
        $('#rowhdr').html('<small>'+r.timestamp+'<br/>'+r.source+'</small>')
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
        $('#ipv4json').html("<pre>"+JSON.stringify(r.ipv4, null, 4)+"</pre>");
        $('#ipv6json').html("<pre>"+JSON.stringify(r.ipv6, null, 4)+"</pre>");                
    };

    $('#show_advanced').click(function(){
        $("#advanced").toggleClass("hidden");
    });
</script>