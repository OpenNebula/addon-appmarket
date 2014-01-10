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
var dataTable_appmarket;
var $appmarket_import_dialog;

var AppMarket = {
    "resource" : "APPMARKET",
    "path" : "appmarket/appliance",

    "create": function(params){
        OpenNebula.Action.create(params, AppMarket.resource, AppMarket.path);
    },
    "show" : function(params){
        OpenNebula.Action.show(params, AppMarket.resource, false, AppMarket.path);
    },
    "del": function(params){
        OpenNebula.Action.del(params, AppMarket.resource, AppMarket.path);
    },
    "update": function(params){
        var callback = params.success;
        var callback_error = params.error;
        var timeout = params.timeout || false;
        var request = OpenNebula.Helper.request('APPMARKET','update');

        $.ajax({
            url: AppMarket.path + '/' + params.data.id,
            type: 'PUT',
            data: params.data.extra_param,
            dataType: "json",
            success: function(response){
                return callback ? callback(request, response) : null;
            },
            error: function(res){
                return callback_error ? callback_error(request, OpenNebula.Error(res)) : null;
            }
        });
    },
    "convert": function(params){
        var callback = params.success;
        var callback_error = params.error;
        var timeout = params.timeout || false;
        var request = OpenNebula.Helper.request('APPMARKET','convert');
        var data = {
            params: {
                format: params.data.extra_param
            }
        }

        $.ajax({
            url: AppMarket.path + '/' + params.data.id + '/convert',
            type: 'POST',
            data: JSON.stringify(data),
            dataType: "json",
            success: function(response){
                return callback ? callback(request, response) : null;
            },
            error: function(res){
                return callback_error ? callback_error(request, OpenNebula.Error(res)) : null;
            }
        });
    },
    "list" : function(params){
        //Custom list request function, since the contents do not come
        //in the same format as the rest of opennebula resources.
        var callback = params.success;
        var callback_error = params.error;
        var timeout = params.timeout || false;
        var request = OpenNebula.Helper.request('APPMARKET','list');

        $.ajax({
            url: AppMarket.path,
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

var Job = {
    "resource" : "JOB",
    "path" : "appmarket/job",

    "create": function(params){
        OpenNebula.Action.create(params, Job.resource, Job.path);
    },
    "show" : function(params){
        OpenNebula.Action.show(params,Job.resource, false, Job.path);
    },
    "list" : function(params){
        //Custom list request function, since the contents do not come
        //in the same format as the rest of opennebula resources.
        var callback = params.success;
        var callback_error = params.error;
        var timeout = params.timeout || false;
        var request = OpenNebula.Helper.request('JOB','list');

        $.ajax({
            url: Job.path,
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

var appconverter_job_actions = {
    "Job.list" : {
        type: "list",
        call: Job.list,
        callback: function(req,res){
            $("#appconverter-jobs #error_message").hide();
            updateView(res,dataTable_appconverter_jobs);
        },
        error: function(request, error_json) {
            onError(request, error_json, $("#appconverter-jobs #error_message"));
        }
    }
}

Sunstone.addActions(appconverter_job_actions);

var appmarket_actions = {
    "AppMarket.create" : {
        type: "create",
        call: AppMarket.create,
        callback: addConverterApplianceElement,
        error: onError,
        notify:true
    },
    "AppMarket.create_dialog" : {
        type : "custom",
        call: popUpCreateConverterApplianceialog
    },
    "AppMarket.list" : {
        type: "list",
        call: AppMarket.list,
        callback: function(req,res){
            $("#apptools-appmarket-appliances #error_message").hide();
            updateView(res.appliances,dataTable_appmarket);
        },
        error: function(request, error_json) {
            onError(request, error_json, $("#apptools-appmarket-appliances #error_message"));
        }
    },
    "AppMarket.refresh" : {
        type: "custom",
        call: function () {
            waitingNodes(dataTable_appmarket);
            Sunstone.runAction('AppMarket.list');
        }
    },
    "AppMarket.delete" : {
        type: "multiple",
        call: AppMarket.del,
        elements: appmarketplaceElements,
        error: onError,
        notify: true
    },
    "AppMarket.update_dialog" : {
        type : "single",
        call: popUpUpdateConverterApplianceialog,
        error: onError
    },
    "AppMarket.show_to_update" : {
        type : "single",
        call: AppMarket.show,
        callback: function(request, response){
            fillUpUpdateConverterApplianceialog(request, response);
            appliance_update_id = request.request.data[0]
        },
        error: onError
    },
    "AppMarket.update" : {
        type: "single",
        call: AppMarket.update,
        callback: function(request,response){
           notifyMessage(tr("Appliance updated correctly"));
           //Sunstone.runAction('ServiceTemplate.show',response.DOCUMENT.ID);
        },
        error: onError
    },
    "AppMarket.convert" : {
        type: "multiple",
        call: AppMarket.convert,
        elements: appmarketplaceElements,
        error:onError,
        notify: true
    },
    "AppMarket.import" : {
        //fetches images information and fills in the image creation
        //dialog with it.
        type: "multiple",
        elements: appmarketplaceElements,
        call: AppMarket.show,
        callback: function(request,response){
            if (response['status'] != 'ready') {
                notifyError(tr("The appliance is not ready"));
                return;
            }

            if ($appmarket_import_dialog != undefined) {
              $appmarket_import_dialog.remove();
            }

            dialogs_context.append(appmarket_import_dialog);
            $appmarket_import_dialog = $('#appmarket_import_dialog',dialogs_context);

            var tab_id = 1;

            $.each(response['files'], function(index, value){
                // Append the new div containing the tab and add the tab to the list
                var image_dialog = $('<li id="'+tab_id+'Tab" class="disk wizard_internal_tab">'+
                  create_image_tmpl +
                '</li>').appendTo($("ul#appmarket_import_dialog_tabs_content"));

                var a_image_dialog = $("<dd>\
                  <a id='disk_tab"+tab_id+"' href='#"+tab_id+"'>"+tr("Image")+"</a>\
                </dd>").appendTo($("dl#appmarket_import_dialog_tabs"));

                initialize_create_image_dialog(image_dialog);
                initialize_datastore_info_create_image_dialog(image_dialog);

                $('#img_name', image_dialog).val(value['name']||response['name']);
                $('#img_path', image_dialog).val(response['links']['download']['href']+'/'+index);
                $('#src_path_select input[value="path"]', image_dialog).trigger('click');
                $('select#img_type', image_dialog).val(value['type']);
                $('select#img_type', image_dialog).trigger('change');

                //remove any options from the custom vars dialog box
                $("#custom_var_image_box",image_dialog).empty();

                var md5 = value['md5']
                if ( md5 ) {
                    option = '<option value=\'' +
                        md5 + '\' name="MD5">MD5=' +
                        md5 + '</option>';
                    $("#custom_var_image_box",image_dialog).append(option);
                }

                var sha1 = value['sha1']
                if ( sha1 ) {
                    option = '<option value=\'' +
                        sha1 + '\' name="SHA1">SHA1=' +
                        sha1 + '</option>';
                    $("#custom_var_image_box",image_dialog).append(option);
                }

                image_dialog.on("reveal:close", function(){
                  a_image_dialog.remove();
                  image_dialog.remove();
                  $(document).foundationTabs("set_tab", $("dl#appmarket_import_dialog_tabs").children().first());
                  return false;
                });

                tab_id++;
            })

            $create_template_dialog.remove();
            // Template
            // Append the new div containing the tab and add the tab to the list
            var template_dialog = $('<li id="'+tab_id+'Tab" class="disk wizard_internal_tab">'+
              create_template_tmpl +
            '</li>').appendTo($("ul#appmarket_import_dialog_tabs_content"));

            var a_template_dialog = $("<dd>\
              <a id='disk_tab"+tab_id+"' href='#"+tab_id+"'>"+tr("Template")+"</a>\
            </dd>").appendTo($("dl#appmarket_import_dialog_tabs"));

            initialize_create_template_dialog(template_dialog);
            fillTemplatePopUp(
              JSON.parse(response['opennebula_template']),
              template_dialog);

            template_dialog.on("reveal:close", function(){
              a_template_dialog.remove();
              template_dialog.remove();
              $(document).foundationTabs("set_tab", $("dl#appmarket_import_dialog_tabs").children().first());
              return false;
            });

            $appmarket_import_dialog.addClass("reveal-modal xlarge max-height");
            $appmarket_import_dialog.reveal();
            //popUpCreateImageDialog();

            $(document).foundationTabs("set_tab", $("dl#appmarket_import_dialog_tabs").children().first());
        },
        error: onError
    },
    "AppMarket.showinfo" : {
        type: "single",
        call: AppMarket.show,
        callback: updateMarketInfo,
        error: onError
    }
}

var appmarket_buttons = {
    "AppMarket.refresh" : {
        type: "action",
        layout: "refresh",
        alwaysActive: true
    },
    "AppMarket.import" : {
        type: "action",
        layout: "main",
        text: tr('Import')
    },
    "AppMarket.create_dialog" : {
        type: "create_dialog",
        layout: "create"
    },
    "AppMarket.update_dialog" : {
        type: "action",
        layout: "main",
        text: tr("Update")
    },
    "AppMarket.convert" : {
        type: "confirm_with_select",
        text: tr("Convert"),
        layout: "main",
        select: function(){
            return '<option class="empty_value" value="">'+tr("Please select")+'</option>\
            <option elem_id="qcow" value="qcow">qcow</option>\
            <option elem_id="vmdk" value="vmdk">vmdk</option>'
        },
        tip: tr("Select the new format, a new appliance will be created")+":"
    },
    "AppMarket.delete" : {
        type: "confirm",
        text: tr("Delete"),
        layout: "del",
        tip: tr("This will delete the selected appliances")
    }
};

var appmarket_import_dialog =
'<div id="appmarket_import_dialog">'+
  '<div class="panel">'+
    '<h3><small>'+tr("Import Appliance")+'</small></h4>'+
  '</div>'+
  '<div class="reveal-body">'+
    '<dl class="tabs" id="appmarket_import_dialog_tabs">'+
    '</dl>'+
    '<ul class="tabs-content" id="appmarket_import_dialog_tabs_content">'+
    '</ul>'+
  '</div>'+
  '<a class="close-reveal-modal">&#215;</a>'+
'</div>';

var create_appconverter_appliance =
'<div class="panel">\
    <h3>\
        <small id="create_appconverter_appliance_header">'+tr("Create Appliance")+'</small>\
        <small id="update_appconverter_appliance_header">'+tr("Update Appliance")+'</small>\
    </h3>\
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
                <button class="button radius right" id="update_appconverter_appliance_manual" value="image/create">'+tr("Update")+'</button>\
                <button class="button secondary radius" id="create_appconverter_appliance_reset"  type="reset" value="reset">'+tr("Reset")+'</button>\
                <button class="close-reveal-modal button secondary radius" type="button" value="close">' + tr("Close") + '</button>\
            </div>\
        </div>\
        <a class="close-reveal-modal">&#215;</a>\
    </form>\
</div>';

var appmarketplace_tab_content = '\
<form class="custom" id="template_form" action="">\
<div class="panel">\
<div class="row">\
  <div class="twelve columns">\
    <h4 class="subheader header">\
      <span class="header-resource">\
       <i class="icon-truck"></i> '+tr("OpenNebula AppMarket")+'\
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
      <table id="datatable_appmarketplace" class="datatable twelve">\
        <thead>\
          <tr>\
            <th class="check"></th>\
            <th>'+tr("ID")+'</th>\
            <th>'+tr("Name")+'</th>\
            <th>'+tr("Status")+'</th>\
            <th>'+tr("Publisher")+'</th>\
            <th>'+tr("Hypervisor")+'</th>\
            <th>'+tr("Arch")+'</th>\
            <th>'+tr("Format")+'</th>\
            <th>'+tr("Tags")+'</th>\
            <th>'+tr("Created")+'</th>\
          </tr>\
        </thead>\
        <tbody id="tbodyappmarketplace">\
        </tbody>\
      </table>\
  </div>\
  </div>\
<div class="row" id="error_message" hidden>\
    <div class="alert-box alert">'+tr("Cannot connect to AppMarket server")+'<a href="" class="close">&times;</a></div>\
</div>\
</form>';


var appmarketplace_tab = {
    title: "Appliances",
    content: appmarketplace_tab_content,
    buttons: appmarket_buttons,
    tabClass: 'subTab',
    parentTab: 'apptools-appmarket-dashboard'
}

Sunstone.addMainTab('apptools-appmarket-appliances', appmarketplace_tab);
Sunstone.addActions(appmarket_actions);


/*
 * INFO PANEL
 */

var appmarketplace_info_panel = {
    "appmarketplace_info_tab" : {
        title: tr("Information"),
        content:""
    }
};

var appmarketplace_jobs_panel = {
    "appmarketplace_jobs_tab" : {
        title: tr("Jobs"),
        content:""
    }
};

var appmarketplace_template_panel = {
    "appmarketplace_template_tab" : {
        title: tr("Template"),
        content:""
    }
};

Sunstone.addInfoPanel("appmarketplace_info_panel", appmarketplace_info_panel);
Sunstone.addInfoPanel("appmarketplace_jobs_panel", appmarketplace_jobs_panel);
Sunstone.addInfoPanel("appmarketplace_template_panel", appmarketplace_template_panel);

function appmarketplaceElements(){
    return getSelectedNodes(dataTable_appmarket);
}

// Callback to add an service_template element
function addConverterApplianceElement(request, template_json){
    addElement(template_json,dataTable_appmarket);
}

function updateMarketInfo(request,app){
    var url = app.links.download.href;
    url = url.replace(/\/download$/, '');
    var info_tab = {
        title : tr("Information"),
        content :
        '<form class="custom"><div class="">\
        <div class="six columns">\
        <table id="info_appmarketplace_table" class="twelve datatable extended_table">\
            <thead>\
              <tr><th colspan="2">'+tr("Information")+'</th></tr>\
            </thead>\
            <tbody>\
              <tr>\
                <td class="key_td">' + tr("ID") + '</td>\
                <td class="value_td">'+app['_id']["$oid"]+'</td>\
              </tr>\
              <tr>\
                <td class="key_td">' + tr("URL") + '</td>\
                <td class="value_td"><a href="'+url+'" target="_blank">'+tr("link")+'</a></td>\
              </tr>\
              <tr>\
                <td class="key_td">' + tr("Publisher") + '</td>\
                <td class="value_td">'+app['publisher']+'</td>\
              </tr>\
              <tr>\
                <td class="key_td">' + tr("Downloads") + '</td>\
                <td class="value_td">'+app['downloads']+'</td>\
              </tr>\
              <tr>\
                <td class="key_td">' + tr("OS") + '</td>\
                <td class="value_td">'+app['files'][0]['os-id']+' '+app['files'][0]['os-release']+'</td>\
              </tr>\
              <tr>\
                <td class="key_td">' + tr("Arch") + '</td>\
                <td class="value_td">'+app['files'][0]['os-arch']+'</td>\
              </tr>\
              <tr>\
                <td class="key_td">' + tr("Size") + '</td>\
                <td class="value_td">'+humanize_size(app['files'][0]['size'],true)+'</td>\
              </tr>\
              <tr>\
                <td class="key_td">' + tr("Hypervisor") + '</td>\
                <td class="value_td">'+app['files'][0]['hypervisor']+'</td>\
              </tr>\
            </tbody>\
        </table>\
        </div>\
        <div class="six columns">\
        <table id="info_appmarketplace_table2" class="twelve datatable extended_table">\
           <thead>\
             <tr><th colspan="2">'+tr("Description")+'</th></tr>\
           </thead>\
           <tbody>\
              <tr>\
                <td class="value_td">'+app['description'].replace(/\n/g, "<br />")+'</td>\
              </tr>\
            </tbody>\
        </table>\
      </div>\
    </form>'
    };

    var jobs_tab = {
        title: tr("Jobs"),
        content : '<div class="columns twelve">\
          <table id="datatable_appconverter_job" class="datatable twelve">\
            <thead>\
              <tr>\
                <th class="check"></th>\
                <th>'+tr("ID")+'</th>\
                <th>'+tr("Name")+'</th>\
                <th>'+tr("Status")+'</th>\
                <th>'+tr("Worker")+'</th>\
                <th>'+tr("Appliance")+'</th>\
                <th>'+tr("Created")+'</th>\
              </tr>\
            </thead>\
            <tbody id="tbodyappconverter_job">\
            </tbody>\
          </table>\
        </div>'
    }

    var template_tab = {
        title: tr("Template"),
        content : '<div class="columns twelve">\
            <table id="template_template_table" class="info_table transparent_table" style="width:80%">'+
            prettyPrintJSON(app)+'\
            </table>\
        </div>'
    }

    Sunstone.updateInfoPanelTab("appmarketplace_info_panel", "appmarketplace_info_tab", info_tab);
    Sunstone.updateInfoPanelTab("appmarketplace_info_panel", "appmarketplace_jobs_tab", jobs_tab);
    Sunstone.updateInfoPanelTab("appmarketplace_info_panel", "appmarketplace_template_tab", template_tab);

    Sunstone.popUpInfoPanel("appmarketplace_info_panel", "apptools-appmarket-appliances");

    dataTable_appconverter_jobs = $("#datatable_appconverter_job").dataTable({
        "bSortClasses": true,
        "sDefaultContent" : "",
        "aoColumns": [
            { "bSortable": false,
              "mData": function ( o, val, data ) {
                  //we render 1st column as a checkbox directly
                  return '<input class="check_item" type="checkbox" id="appconverter_job_'+
                      o['_id']['$oid']+
                      '" name="selected_items" value="'+
                      o['_id']['$oid']+'"/>'
              },
              "sWidth" : "60px",
              "bVisible": false
            },
            { "mData": "_id.$oid", "sWidth" : "200px" },
            { "mData": "name" },
            { "mData": "status" },
            { "mData": "worker_host", "sDefaultContent" : "-" },
            { "mData": "appliance_id", "sDefaultContent" : "-" },
            { "mData": function (source) {
              return pretty_time(source.creation_time)
            } }
          ],
          "aoColumnDefs": [
            //{ "bVisible": true, "aTargets": Config.tabTableColumns(tab_name)},
            //{ "bVisible": false, "aTargets": ['_all']}
        ]
    });

    Sunstone.runAction('Job.list');

    $("#appmarketplace_info_panel_refresh", $("#appmarketplace_info_panel")).click(function(){
      $(this).html(spinner);
      Sunstone.runAction('AppMarket.showinfo', app['_id']["$oid"]);
    })

    dataTable_appconverter_jobs.fnFilter(app['_id']['$oid'], 5, true);

};

 function infoListenerAppMarket(dataTable){
    $('tbody tr',dataTable).live("click",function(e){

    if ($(e.target).is('input') ||
        $(e.target).is('select') ||
        $(e.target).is('option')) return true;

    var aData = dataTable.fnGetData(this);
    var id =aData["_id"]["$oid"];
    if (!id) return true;
        popDialogLoading();
        Sunstone.runAction("AppMarket.showinfo",id);

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
        Sunstone.runAction("AppMarket.create",JSON.parse(template));
        $create_converter_appliance_dialog.trigger("reveal:close")
        return false;
    });

    $('#update_appconverter_appliance_manual',dialog).click(function(){
        var template=$('#template',dialog).val();
        Sunstone.runAction("AppMarket.update", appliance_update_id, template);
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
    var dialog = $create_converter_appliance_dialog;

    $("#create_appconverter_appliance_header", dialog).show();
    $("#update_appconverter_appliance_header", dialog).hide();
    $("#create_appconverter_appliance_manual", dialog).show();
    $("#update_appconverter_appliance_manual", dialog).hide();

    $create_converter_appliance_dialog.reveal();
}

function popUpUpdateConverterApplianceialog(){
    var dialog = $create_converter_appliance_dialog;

    var selected_nodes = getSelectedNodes(dataTable_appmarket);
    if ( selected_nodes.length != 1 ) {
      notifyMessage("Please select one (and just one) appliance to update.");
      return false;
    }

    var appliance_id = ""+selected_nodes[0];
    Sunstone.runAction("AppMarket.show_to_update", appliance_id);

    $("#create_appconverter_appliance_header", dialog).hide();
    $("#update_appconverter_appliance_header", dialog).show();
    $("#create_appconverter_appliance_manual", dialog).hide();
    $("#update_appconverter_appliance_manual", dialog).show();

    $create_converter_appliance_dialog.reveal();
}

function fillUpUpdateConverterApplianceialog(request, response){
    var template_json = response;
    delete template_json["_id"];
    delete template_json["downloads"];
    delete template_json["visits"];
    delete template_json["status"];

    $('#template',$create_converter_appliance_dialog).val(JSON.stringify(template_json, undefined, 2));
}

/*
 * Document
 */

$(document).ready(function(){
    var tab_name = 'apptools-appmarket-appliances';

    if (Config.isTabEnabled(tab_name)) {
      dataTable_appmarket = $("#datatable_appmarketplace", main_tabs_context).dataTable({
          "bSortClasses": true,
          "aoColumns": [
              { "bSortable": false,
                "mData": function ( o, val, data ) {
                    //we render 1st column as a checkbox directly
                    return '<input class="check_item" type="checkbox" id="appmarketplace_'+
                        o['_id']['$oid']+
                        '" name="selected_items" value="'+
                        o['_id']['$oid']+'"/>'
                },
                "sWidth" : "60px"
              },
              { "mData": "_id.$oid", "sWidth" : "200px" },
              { "mData": "name" },
              { "mData": "status" },
              { "mData": "publisher" },
              { "mData": "files.0.hypervisor", "sWidth" : "100px"},
              { "mData": "files.0.os-arch", "sWidth" : "100px"},
              { "mData": "files.0.format", "sWidth" : "100px"},
              { "mData": "tags"},
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
        dataTable_appmarket.fnFilter( $(this).val() );
      })

      dataTable_appmarket.on('draw', function(){
        recountCheckboxes(dataTable_appmarket);
      })


      tableCheckboxesListener(dataTable_appmarket);
      onlyOneCheckboxListener(dataTable_appmarket);

      infoListenerAppMarket(dataTable_appmarket);

      Sunstone.runAction('AppMarket.list');

      setupCreateConverterApplianceDialog();
  }
});
