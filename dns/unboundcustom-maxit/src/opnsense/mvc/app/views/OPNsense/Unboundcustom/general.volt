{#
 # Copyright (c) 2021 Michael Muenz <m.muenz@max-it.de>
 # All rights reserved.
 #}

<div class="content-box" style="padding-bottom: 1.5em;">
    <div class="alert alert-warning" role="alert" style="min-height:65px;">
        <div style="margin-top: 8px;">{{ lang._('For initial setup, enable the daemon and browse to your Firewall on port 8080.') }}</div>
        <div style="margin-top: 8px;">{{ lang._('After initial setup, browse your Firewall on port 8443 for WiFi management.') }}</div>
    </div>
    {{ partial("layout_partials/base_form",['fields':generalForm,'id':'frm_general_settings'])}}
    <div class="col-md-12">
        <hr />
        <button class="btn btn-primary" id="saveAct" type="button"><b>{{ lang._('Save') }}</b> <i id="saveAct_progress"></i></button>
    </div>
</div>

<script>
    $(function() {
        var data_get_map = {'frm_general_settings':"/api/unifi/general/get"};
        mapDataToFormUI(data_get_map).done(function(data){
            formatTokenizersUI();
            $('.selectpicker').selectpicker('refresh');
        });

        updateServiceControlUI('unifi');

        $("#saveAct").click(function(){
            saveFormToEndpoint(url="/api/unifi/general/set", formid='frm_general_settings',callback_ok=function(){
            $("#saveAct_progress").addClass("fa fa-spinner fa-pulse");
                ajaxCall(url="/api/unifi/service/reconfigure", sendData={}, callback=function(data,status) {
                    updateServiceControlUI('unifi');
                    $("#saveAct_progress").removeClass("fa fa-spinner fa-pulse");
                });
            });
        });

    });
</script>
