{#

#}
<ul class="nav nav-tabs" data-tabs="tabs" id="maintabs">
    <li class="active"><a data-toggle="tab" href="general" onClick="parent.location='general'">{{ lang._('CLI Settings') }}</a></li>
    <li><a data-toggle="tab" href="logs" onClick="parent.location='logs'">{{ lang._('Logs') }}</a></li>
</ul>


<div class="tab-content content-box tab-content">
    <div id="general" class="tab-pane fade in active">
        <div class="content-box" style="padding-bottom: 1.5em;">
            {{ partial("layout_partials/base_form",['fields':generalForm,'id':'frm_general_settings'])}}
            <div class="col-md-12">
                <hr />
                <button class="btn btn-primary" id="saveAct" type="button"><b>{{ lang._('Save') }}</b> <i id="saveAct_progress"></i></button>
            </div>
        </div>
    </div>
</div>

<script>
$( document ).ready(function() {
    var data_get_map = {'frm_general_settings':"/api/nextdns/general/get"};
    mapDataToFormUI(data_get_map).done(function(data){
        formatTokenizersUI();
        $('.selectpicker').selectpicker('refresh');
    });

    updateServiceControlUI('nextdns');
    
    $("div.col-md-12").append('<button class="btn btn-primary" id="nextdns" type="button" onclick="window.open(\'https\:\/\/my.nextdns.com\')"><b> my.nextdns.com</b></button>');

    $("#saveAct").click(function(){
        saveFormToEndpoint(url="/api/nextdns/general/set", formid='frm_general_settings',callback_ok=function(){
        $("#saveAct_progress").addClass("fa fa-spinner fa-pulse");
            ajaxCall(url="/api/nextdns/service/reconfigure", sendData={}, callback=function(data,status) {
		        updateServiceControlUI('nextdns');
                $("#saveAct_progress").removeClass("fa fa-spinner fa-pulse");
            });
        });
    });

});
</script>
