// ------------------------------------------------------------------------ //
// Copyright 2002-2013, OpenNebula Project (OpenNebula.org), C12G Labs      //
//                                                                          //
// Licensed under the Apache License, Version 2.0 (the "License"); you may  //
// not use this file except in compliance with the License. You may obtain  //
// a copy of the License at                                                 //
//                                                                          //
// http://www.apache.org/licenses/LICENSE-2.0                               //
//                                                                          //
// Unless required by applicable law or agreed to in writing, software      //
// distributed under the License is distributed on an "AS IS" BASIS,        //
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. //
// See the License for the specific language governing permissions and      //
// limitations under the License.                                           //
//------------------------------------------------------------------------- //

/* Marketpplace tab plugin */
var dataTable_appconverter_appliances;
var $create_converter_appliance_dialog;

var Appliance = {
    "resource" : "APPLIANCE",
    "path" : "appconverter/appliance",

    "create": function(params){
        OpenNebula.Action.create(params, Appliance.resource, Appliance.path);
    },
    "show" : function(params){
        OpenNebula.Action.show(params,Appliance.resource, false, Appliance.path);
    },
    "list" : function(params){
        //Custom list request function, since the contents do not come
        //in the same format as the rest of opennebula resources.
        var callback = params.success;
        var callback_error = params.error;
        var timeout = params.timeout || false;
        var request = OpenNebula.Helper.request('APPLIANCE','list');

        $.ajax({
            url: Appliance.path,
            type: 'GET',
            data: {timeout: timeout},
            dataType: "json",
            success: function(response){
                return callback ?
                    callback(request, response) : null;
            },
            error: function(res){
                return callback_error ? callback_error(request, OpenNebula.Error(res)) : null;
            }
        });
    }
}
var appconverter_appliance_actions = {
    "Appliance.create" : {
        type: "create",
        call: Appliance.create,
        callback: addConverterApplianceElement,
        error: onError,
        notify:true
    },
    "Appliance.create_dialog" : {
        type : "custom",
        call: popUpCreateConverterApplianceialog
    },
    "Appliance.list" : {
        type: "list",
        call: Appliance.list,
        callback: function(req,res){
            $("#appconverter-appliances #error_message").hide();
            updateView(res,dataTable_appconverter_appliances);
        },
        error: function(request, error_json) {
            onError(request, error_json, $("#appconverter-appliances #error_message"));
        }
    },
    "Appliance.refresh" : {
        type: "custom",
        call: function () {
            waitingNodes(dataTable_appconverter_appliances);
            Sunstone.runAction('Appliance.list');
        }
    },
    "Appliance.showinfo" : {
        type: "single",
        call: Appliance.show,
        callback: updateApplianceInfo,
        error: onError
    }
}

var appconverter_appliance_buttons = {
    "Appliance.refresh" : {
        type: "action",
        layout: "refresh",
        alwaysActive: true
    },
    "Appliance.create_dialog" : {
        type: "create_dialog",
        layout: "create"
    }
};

var appconverter_appliance_tab_content = '\
<form class="custom" id="template_form" action="">\
<div class="panel">\
<div class="row">\
  <div class="twelve columns">\
    <h4 class="subheader header">\
      <span class="header-resource">\
       <i class="icon-exchange"></i> '+tr("AppConverter Appliances")+'\
      </span>\
      <span class="header-info">\
        <span/> <small></small>&emsp;\
      </span>\
      <span class="user-login">\
      </span>\
    </h4>\
  </div>\
</div>\
<div class="row">\
  <div class="nine columns">\
    <div class="action_blocks">\
    </div>\
  </div>\
  <div class="three columns">\
    <input id="appliances_search" type="text" placeholder="'+tr("Search")+'" />\
  </div>\
  <br>\
  <br>\
</div>\
</div>\
  <div class="row">\
    <div class="twelve columns">\
      <table id="datatable_appconverter_appliance" class="datatable twelve">\
        <thead>\
          <tr>\
            <th class="check"></th>\
            <th>'+tr("ID")+'</th>\
            <th>'+tr("Name")+'</th>\
            <th>'+tr("Status")+'</th>\
            <th>'+tr("Created")+'</th>\
          </tr>\
        </thead>\
        <tbody id="tbodyappconverter_appliance">\
        </tbody>\
      </table>\
  </div>\
  </div>\
<div class="row" id="error_message" hidden>\
    <div class="alert-box alert">'+tr("Cannot connect to AppConverter server")+'<a href="" class="close">&times;</a></div>\
</div>\
</form>';

var create_appconverter_appliance =
'<div class="panel">\
    <h3><small>'+tr("Create Appliance")+'</small></h4>\
</div>\
<div class="reveal-body">\
    <form id="create_appconverter_appliance" action="" class="custom creation">\
        <div class="reveal-body">\
            <textarea id="template" rows="15" style="width:100%;"></textarea>\
        </div>\
        <div class="reveal-footer">\
            <hr>\
            <div class="form_buttons">\
                <button class="button success radius right" id="create_appconverter_appliance_manual" value="image/create">'+tr("Create")+'</button>\
                <button class="button secondary radius" id="create_appconverter_appliance_reset"  type="reset" value="reset">'+tr("Reset")+'</button>\
                <button class="close-reveal-modal button secondary radius" type="button" value="close">' + tr("Close") + '</button>\
            </div>\
        </div>\
        <a class="close-reveal-modal">&#215;</a>\
    </form>\
</div>';

var appconverter_appliance = {
    title: "Appliances",
    content: appconverter_appliance_tab_content,
    buttons: appconverter_appliance_buttons,
    tabClass: 'subTab',
    parentTab: 'appconverter-dashboard'
}

Sunstone.addMainTab('appconverter-appliances', appconverter_appliance);
Sunstone.addActions(appconverter_appliance_actions);


/*
 * INFO PANEL
 */

var appconverter_appliance_info_panel = {
    "appconverter_appliance_info_tab" : {
        title: tr("Appliance information"),
        content:""
    }
};

Sunstone.addInfoPanel("appconverter_appliance_info_panel", appconverter_appliance_info_panel);

function appconverter_applianceElements(){
    return getSelectedNodes(dataTable_appconverter_appliances);
}

// Callback to add an service_template element
function addConverterApplianceElement(request, template_json){
    addElement(template_json,dataTable_appconverter_appliances);
}

function updateApplianceInfo(request,app){
    console.log(app)
    var info_tab = {
        title : tr("Appliance information"),
        content :
        '<form class="custom"><div class="">\
        <div class="six columns">\
        <table id="info_appconverter_appliancele" class="twelve datatable extended_table">\
            <thead>\
              <tr><th colspan="2">'+tr("Appliance information")+'</th></tr>\
            </thead>\
            <tbody>\
              <tr>\
                <td class="key_td">' + tr("ID") + '</td>\
                <td class="value_td">'+app['_id']["$oid"]+'</td>\
              </tr>\
              <tr>\
                <td class="key_td">' + tr("Name") + '</td>\
                <td class="value_td">'+app['name']+'</td>\
              </tr>\
              <tr>\
                <td class="key_td">' + tr("Created") + '</td>\
                <td class="value_td">'+pretty_time(app['creation_time'])+'</td>\
              </tr>\
              <tr>\
                <td class="key_td">' + tr("Status") + '</td>\
                <td class="value_td">'+app['status']+'</td>\
              </tr>\
            </tbody>\
        </table>\
        </div>\
        <div class="six columns">\
        <table id="info_appconverter_appliancele2" class="twelve datatable extended_table">\
           <thead>\
             <tr><th colspan="2">'+tr("Description")+'</th></tr>\
           </thead>\
           <tbody>\
            </tbody>\
        </table>\
      </div>\
    </form>'
    };

    Sunstone.updateInfoPanelTab("appconverter_appliance_info_panel", "appconverter_appliance_info_tab", info_tab);
    Sunstone.popUpInfoPanel("appconverter_appliance_info_panel", "appconverter-appliances");
};

 function infoListenerAppliance(dataTable){
    $('tbody tr',dataTable).live("click",function(e){

    if ($(e.target).is('input') ||
        $(e.target).is('select') ||
        $(e.target).is('option')) return true;

    var aData = dataTable.fnGetData(this);
    var id =aData["_id"]["$oid"];
    if (!id) return true;
        popDialogLoading();
        Sunstone.runAction("Appliance.showinfo",id);

        // Take care of the coloring business
        // (and the checking, do not forget the checking)
        $('tbody input.check_item',$(this).parents('table')).removeAttr('checked');
        $('.check_item',this).click();
        $('td',$(this).parents('table')).removeClass('markrowchecked');

        if(last_selected_row)
            last_selected_row.children().each(function(){$(this).removeClass('markrowselected');});
        last_selected_row = $("td:first", this).parent();
        $("td:first", this).parent().children().each(function(){$(this).addClass('markrowselected');});

        return false;
    });
}


/*
 * onlyOneCheckboxListener: Only one box can be checked
 */

function onlyOneCheckboxListener(dataTable) {
    $('tbody input.check_item', dataTable).live("change", function(){
        var checked = $(this).is(':checked');
        $('input.check_item:checked', dataTable).removeAttr('checked');
        $(this).attr('checked', checked);
    });
}

// Prepare the image creation dialog
function setupCreateConverterApplianceDialog(){
    dialogs_context.append('<div id="create_converter_appliance_dialog"></div>');
    $create_converter_appliance_dialog =  $('#create_converter_appliance_dialog',dialogs_context);

    var dialog = $create_converter_appliance_dialog;
    dialog.html(create_appconverter_appliance);

    setupTips($create_converter_appliance_dialog);

    dialog.addClass("reveal-modal large max-height");

    $('#create_appconverter_appliance_manual',dialog).click(function(){
        var template=$('#template',dialog).val();
        Sunstone.runAction("Appliance.create",JSON.parse(template));
        $create_converter_appliance_dialog.trigger("reveal:close")
        return false;
    });

    $('#create_appconverter_appliance_reset').click(function(){
        $create_converter_appliance_dialog.trigger('reveal:close');
        $create_converter_appliance_dialog.remove();
        setupCreateConverterApplianceDialog();

        popUpCreateConverterApplianceialog();
    });
}

function popUpCreateConverterApplianceialog(){
    $create_converter_appliance_dialog.reveal();
}
/*
 * Document
 */

$(document).ready(function(){
    var tab_name = 'appconverter-appliances';

    if (Config.isTabEnabled(tab_name)) {
      dataTable_appconverter_appliances = $("#datatable_appconverter_appliance", main_tabs_context).dataTable({
          "bSortClasses": true,
          "aoColumns": [
              { "bSortable": false,
                "mData": function ( o, val, data ) {
                    //we render 1st column as a checkbox directly
                    return '<input class="check_item" type="checkbox" id="appconverter_appliance_'+
                        o['_id']['$oid']+
                        '" name="selected_items" value="'+
                        o['_id']['$oid']+'"/>'
                },
                "sWidth" : "60px"
              },
              { "mData": "_id.$oid", "sWidth" : "200px" },
              { "mData": "name" },
              { "mData": "status" },
              { "mData": function (source) {
                return pretty_time(source.creation_time)
              } }
            ],
            "aoColumnDefs": [
              { "bVisible": true, "aTargets": Config.tabTableColumns(tab_name)},
              { "bVisible": false, "aTargets": ['_all']}
          ]
      });

      $('appliances_search').keyup(function(){
        dataTable_appconverter_appliances.fnFilter( $(this).val() );
      })

      dataTable_appconverter_appliances.on('draw', function(){
        recountCheckboxes(dataTable_appconverter_appliances);
      })

      tableCheckboxesListener(dataTable_appconverter_appliances);
      onlyOneCheckboxListener(dataTable_appconverter_appliances);

      infoListenerAppliance(dataTable_appconverter_appliances);

      Sunstone.runAction('Appliance.list');

      setupCreateConverterApplianceDialog();
  }
});
