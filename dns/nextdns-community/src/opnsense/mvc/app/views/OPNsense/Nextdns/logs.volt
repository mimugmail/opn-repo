{#
 #}
 <ul class="nav nav-tabs" data-tabs="tabs" id="maintabs">
    <li><a data-toggle="tab" href="general" onClick="parent.location='general'">{{ lang._('CLI Settings') }}</a></li>
    <li class="active" ><a data-toggle="tab" href="logs" onClick="parent.location='logs'">{{ lang._('Logs') }}</a></li>
</ul>

<div class="content-box tab-content">
    <div id="systemlog" class="tab-pane fade in active">
        <div class="content-box" style="padding-bottom: 1.5em;">
            <div  class="col-sm-12">
                <table id="grid-systemlog" class="table table-condensed table-hover table-striped table-responsive" data-store-selection="true">
                    <thead>
                    <tr>
                        <th data-column-id="timestamp" data-width="11em" data-type="string">{{ lang._('Date') }}</th>
                        <th data-column-id="process_name" data-width="11em" data-type="string">{{ lang._('Process') }}</th>
                        <th data-column-id="line" data-type="string">{{ lang._('Line') }}</th>
                    </tr>
                    </thead>
                    <tbody>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<script>
    $( document ).ready(function() {
      // get entries from system log for 'nextdns'
      let grid_systemlog = $("#grid-systemlog").UIBootgrid({
          options:{
              navigation:3,
              sorting:false,
              rowSelect: false,
              selection: false,
              rowCount:[20,50,100,200,500,1000,-1],
              requestHandler: function(request){
                  // Show only log entries that match 'nextdns'
                  request['searchPhrase'] = 'nextdns';
                  return request;
              },
          },
          search:'/api/diagnostics/log/core/configd'
      });
    // Hide nonfunctional search field
      $("div .search").remove()

      grid_systemlog.on("loaded.rs.jquery.bootgrid", function(){
          $(".action-page").click(function(event){
              event.preventDefault();
              $("#grid-systemlog").bootgrid("search",  "");
              let new_page = parseInt((parseInt($(this).data('row-id')) / $("#grid-log").bootgrid("getRowCount")))+1;
              $("input.search-field").val("");
              // XXX: a bit ugly, but clearing the filter triggers a load event.
              setTimeout(function(){
                  $("ul.pagination > li:last > a").data('page', new_page).click();
              }, 100);
          });
      });

    });
</script>
