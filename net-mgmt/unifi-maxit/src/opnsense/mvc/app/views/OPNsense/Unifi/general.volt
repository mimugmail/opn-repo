{#
 # Copyright (c) 2021 Michael Muenz <m.muenz@max-it.de>
 # All rights reserved.
 #}

<div class="content-box" style="padding-bottom: 1.5em;">
    {{ partial("layout_partials/base_form",['fields':generalForm,'id':'frm_general_settings'])}}
    <div class="col-md-12">
        <hr />
        <button class="btn btn-primary" id="saveAct" type="button"><b>{{ lang._('Save') }}</b> <i id="saveAct_progress"></i></button>
    </div>
</div>

<script>
    $(function() {
        function updateControllerLinks(port) {
            port = port || $('#general\\.port_gui').val() || '8443';
            var url = 'https://' + window.location.hostname + ':' + port;
            $('#unifi_controller_url_btn').attr('href', url);
            $('#unifi_controller_url_text').text(url);
        }

        var controllerUrlHtml = '<tr id="row_general.controller_url">' +
            '<td><div class="control-label"><b>{{ lang._("UniFi Controller") }}</b></div></td>' +
            '<td>' +
                '<a href="#" id="unifi_controller_url_btn" target="_blank" rel="noopener noreferrer" class="btn btn-default btn-sm" style="font-weight: 600;">' +
                    '<i class="fa fa-external-link"></i> <span id="unifi_controller_url_text">https://' + window.location.hostname + ':8443</span>' +
                '</a>' +
            '</td>' +
            '<td></td>' +
        '</tr>';
        $('#row_general\\.enabled').after(controllerUrlHtml);

        var daysHtml = '<tr id="row_general.days">' +
            '<td><div class="control-label"><b>{{ lang._("Days") }}</b></div></td>' +
            '<td>' +
                '<div style="display: flex; gap: 15px; text-align: center;">' +
                    '<div><div><label for="general.days_mon" style="font-weight: normal; margin-bottom: 2px; cursor: pointer;"><small>{{ lang._("Mon") }}</small></label></div><input type="checkbox" id="general.days_mon"></div>' +
                    '<div><div><label for="general.days_tue" style="font-weight: normal; margin-bottom: 2px; cursor: pointer;"><small>{{ lang._("Tue") }}</small></label></div><input type="checkbox" id="general.days_tue"></div>' +
                    '<div><div><label for="general.days_wed" style="font-weight: normal; margin-bottom: 2px; cursor: pointer;"><small>{{ lang._("Wed") }}</small></label></div><input type="checkbox" id="general.days_wed"></div>' +
                    '<div><div><label for="general.days_thu" style="font-weight: normal; margin-bottom: 2px; cursor: pointer;"><small>{{ lang._("Thu") }}</small></label></div><input type="checkbox" id="general.days_thu"></div>' +
                    '<div><div><label for="general.days_fri" style="font-weight: normal; margin-bottom: 2px; cursor: pointer;"><small>{{ lang._("Fri") }}</small></label></div><input type="checkbox" id="general.days_fri"></div>' +
                    '<div><div><label for="general.days_sat" style="font-weight: normal; margin-bottom: 2px; cursor: pointer;"><small>{{ lang._("Sat") }}</small></label></div><input type="checkbox" id="general.days_sat"></div>' +
                    '<div><div><label for="general.days_sun" style="font-weight: normal; margin-bottom: 2px; cursor: pointer;"><small>{{ lang._("Sun") }}</small></label></div><input type="checkbox" id="general.days_sun"></div>' +
                '</div>' +
            '</td>' +
            '<td></td>' +
        '</tr>';
        $('#row_general\\.schedule_stop_hour').after(daysHtml);

        var maintHtml = '<tr id="row_general.maintenance">' +
            '<td><div class="control-label"><b>{{ lang._("Maintenance") }}</b></div></td>' +
            '<td>' +
                '<button class="btn btn-default btn-xs" type="button" id="btn_truncate_log">' +
                    '<i class="fa fa-trash-o"></i> {{ lang._("Truncate mongod.log") }} <i id="truncate_progress"></i>' +
                '</button>' +
                '&nbsp;' +
                '<button class="btn btn-default btn-xs" type="button" id="btn_compact_db">' +
                    '<i class="fa fa-database"></i> {{ lang._("Compact Database") }} <i id="compact_progress"></i>' +
                '</button>' +
            '</td>' +
            '<td></td>' +
        '</tr>';
        $('#row_general\\.port_gui').after(maintHtml);

        $('#btn_truncate_log').click(function(){
            $('#truncate_progress').addClass('fa fa-spinner fa-pulse');
            ajaxCall('/api/unifi/service/truncateLog', {}, function(data, status) {
                $('#truncate_progress').removeClass('fa fa-spinner fa-pulse');
            });
        });

        $('#btn_compact_db').click(function(){
            $('#compact_progress').addClass('fa fa-spinner fa-pulse');
            ajaxCall('/api/unifi/service/compactDb', {}, function(data, status) {
                $('#compact_progress').removeClass('fa fa-spinner fa-pulse');
            });
        });

        var data_get_map = {'frm_general_settings':"/api/unifi/general/get"};
        mapDataToFormUI(data_get_map).done(function(data){
            formatTokenizersUI();
            $('.selectpicker').selectpicker('refresh');
            if (data && data.frm_general_settings && data.frm_general_settings.general && data.frm_general_settings.general.port_gui) {
                updateControllerLinks(data.frm_general_settings.general.port_gui);
            } else {
                updateControllerLinks();
            }
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
