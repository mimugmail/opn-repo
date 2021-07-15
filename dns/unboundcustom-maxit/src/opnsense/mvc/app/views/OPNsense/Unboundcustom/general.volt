{#
 # Copyright (c) 2021 Michael Muenz <m.muenz@max-it.de>
 # All rights reserved.
 #}

<div class="content-box" style="padding-bottom: 1.5em;">
    <div class="alert alert-warning" role="alert" style="min-height:65px;">
        <div style="margin-top: 8px;">{{ lang._('Clicking Save only saves the config and does not restart Unbound') }}</div>
    </div>
    {{ partial("layout_partials/base_form",['fields':generalForm,'id':'frm_general_settings'])}}
    <div class="col-md-12">
        <hr />
        <button class="btn btn-primary" id="saveAct" type="button"><b>{{ lang._('Save') }}</b> <i id="saveAct_progress"></i></button>
    </div>
</div>

<script>
    $(function() {
        var data_get_map = {'frm_general_settings':"/api/unboundcustom/general/get"};
        mapDataToFormUI(data_get_map).done(function(data){
            formatTokenizersUI();
            $('.selectpicker').selectpicker('refresh');
        });

        $("#saveAct").click(function(){
            saveFormToEndpoint(url="/api/unboundcustom/general/set", formid='frm_general_settings',callback_ok=function(){
            $("#saveAct_progress").addClass("fa fa-spinner fa-pulse");
                ajaxCall(url="/api/unboundcustom/service/reconfigure", sendData={}, callback=function(data,status) {
                    updateServiceControlUI('unboundcustom');
                    $("#saveAct_progress").removeClass("fa fa-spinner fa-pulse");
                });
            });
        });

    });
</script>
