<?php

?>

<div class="tab-content content-box tab-content">
    <div id="general" class="tab-pane fade in active">
        <div class="content-box" style="padding-bottom: 1.5em;">
            {{ partial("layout_partials/base_form",['fields':settingsForm,'id':'frm_general_settings'])}}
            <div class="col-md-12">
                <hr />
                <button class="btn btn-primary" id="saveAct" type="button"><b>{{ lang._('Save') }}</b> <i id="saveAct_progress"></i></button>
            </div>
        </div>
    </div>
</div>

<script>
    $( document ).ready(function() {
        var data_get_map = {'frm_general_settings':"/api/unifi/settings/get"};
        mapDataToFormUI(data_get_map).done(function(data){
            formatTokenizersUI();
            $('.selectpicker').selectpicker('refresh');
        });

        $("#saveAct").click(function(){
            saveFormToEndpoint(url="/api/unifi/settings/set", formid='frm_general_settings',callback_ok=function(){
            $("#saveAct_progress").addClass("fa fa-spinner fa-pulse");
                ajaxCall(url="/api/unifi/settings/reconfigure", sendData={}, callback=function(data,status) {
                    $("#saveAct_progress").removeClass("fa fa-spinner fa-pulse");
                });
            });
        });
    
    });
    </script>