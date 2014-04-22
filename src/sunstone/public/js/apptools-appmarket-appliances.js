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
var $appmarket_convert_dialog;

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
        var request = OpenNebula.Helper.request('APPMARKET','update', [params.data.id]);

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
        var request = OpenNebula.Helper.request('APPMARKET','convert', [params.data.id]);
        var data = params.data.extra_param;

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
    "del": function(params){
        OpenNebula.Action.del(params, Job.resource, Job.path);
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
    },
    "Job.delete" : {
        type: "multiple",
        call: Job.del,
        callback: jobCallback,
        elements: jobElements,
        error: onError,
        notify: true
    }
}

Sunstone.addActions(appconverter_job_actions);

function jobElements() {
    return getSelectedNodes(dataTable_appconverter_jobs, true);
};

function jobCallback() {
    return $("#appmarketplace_info_panel_refresh", $("#appmarketplace_info_panel")).click();
}

var job_buttons = {
    "Job.delete" : {
        type: "action",
        text: tr("Delete"),
        layout: "del",
        tip: tr("This will delete the selected VMs from the database")
    }
}

var appmarket_actions = {
    "AppMarket.create" : {
        type: "create",
        call: AppMarket.create,
        callback: function(request, response) {
            $create_converter_appliance_dialog.foundation('reveal', 'close');
            addConverterApplianceElement(request, response);
        },
        error: onError,
        notify:true
    },
    "AppMarket.create_dialog" : {
        type : "custom",
        call: popUpCreateApplianceDialog
    },
    "AppMarket.convert" : {
        type: "single",
        call: AppMarket.convert,
        callback: function(request, response) {
            addConverterApplianceElement(request, response);
        },
        error: onError,
        notify:true
    },
    "AppMarket.convert_dialog" : {
        type : "custom",
        call: popUpConvertApplianceDialog
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
          var tab = dataTable_appmarket.parents(".tab");
          if (Sunstone.rightInfoVisible(tab)) {
            Sunstone.runAction("AppMarket.show", Sunstone.rightInfoResourceId(tab))
          } else {
            waitingNodes(dataTable_appmarket);
            Sunstone.runAction("AppMarket.list");
          }
        }
    },
    "AppMarket.delete" : {
        type: "multiple",
        call: AppMarket.del,
        elements: appmarketplaceElements,
        callback: deleteMarketElement,
        error: onError,
        notify: true
    },
    "AppMarket.update_dialog" : {
        type : "single",
        call: popUpUpdateApplianceDialog,
        error: onError
    },
    "AppMarket.show_to_update" : {
        type : "single",
        call: AppMarket.show,
        callback: function(request, response){
            fillUpUpdateApplianceDialog(request, response);
            appliance_update_id = request.request.data[0]
        },
        error: onError
    },
    "AppMarket.update" : {
        type: "single",
        call: AppMarket.update,
        callback: function(request,response){
            Sunstone.runAction("AppMarket.show", request.request.data[0]);
            $create_converter_appliance_dialog.foundation('reveal', 'close');
        },
        error: onError
    },
    "AppMarket.import" : {
        //fetches images information and fills in the image creation
        //dialog with it.
        type: "multiple",
        elements: appmarketplaceElements,
        call: AppMarket.show,
        callback: function(request,appliance){
            if (appliance['status'] && appliance['status'] != 'ready') {
                notifyError(tr("The appliance is not ready"));
                return;
            }

            if ($('#appmarket_import_dialog',dialogs_context) != undefined) {
              $('#appmarket_import_dialog',dialogs_context).remove();
            }

            dialogs_context.append(appmarket_import_dialog);
            $appmarket_import_dialog = $('#appmarket_import_dialog',dialogs_context);
            $appmarket_import_dialog.addClass("reveal-modal medium").attr("data-reveal", "");

            //var tab_id = 1;
            $('<div class="row">'+
                '<div class="large-12 columns">'+
                    '<p style="font-size:14px">'+
                        tr("The following images will be created in OpenNebula.")+ ' '+
                        tr("If you want to edit parameters of the image you can do it later in the images tab")+ ' '+
                    '</p>'+
                '</div>'+
            '</div>').appendTo($("#appmarket_import_dialog_content"));

            $('<div class="row">'+
                '<div class="large-10 large-centered columns">'+
                    '<div class="large-10 columns">'+
                        '<label for="appmarket_img_datastore">'+tr("Select the datastore for the images")+
                        '</label>'+
                        '<div id="appmarket_img_datastore" name="appmarket_img_datastore">'+
                        '</div>'+
                    '</div>'+
                    '<div class="large-2 columns">'+
                    '</div>'+
                '</div>'+
            '</div>').appendTo($("#appmarket_import_dialog_content"));

            // Filter out DS with type system (1) or file (2)
            var filter_att = ["TYPE", "TYPE"];
            var filter_val = ["1", "2"];

            insertSelectOptions('div#appmarket_img_datastore', $appmarket_import_dialog, "Datastore",
                                null, false, null, filter_att, filter_val);

            $.each(appliance['files'], function(index, value){
                $('<div class="row" id="appmarket_import_file_'+index+'">'+
                    '<div class="large-10 large-centered columns">'+
                        '<div class="large-10 columns">'+
                            '<label>'+
                                '<i class="fa fa-fw fa-download"/>&emsp;'+
                                index+' - '+tr("Image Name")+
                                '<span class="right">'+
                                    humanize_size(value['size'], true)+
                                '</span>'+
                            '</label>'+
                            '<input type="text" class="name"    value="' + (value['name']||appliance['name']) +'" />'+
                        '</div>'+
                        '<div class="large-2 columns appmarket_image_result">'+
                        '</div>'+
                    '</div>'+
                    '<div class="large-10 large-centered columns appmarket_image_response">'+
                    '</div>'+
                '</div>').appendTo($("#appmarket_import_dialog_content"));
            })

            if (appliance['opennebula_template'] && appliance['opennebula_template'] !== "CPU=1") {
                $('<br>'+
                '<div class="row">'+
                    '<div class="large-12 columns">'+
                        '<p style="font-size:14px">'+
                            tr("The following template will be created in OpenNebula and the previous images will be referenced in the disks")+ ' '+
                            tr("If you want to edit parameters of the template you can do it later in the templates tab")+ ' '+
                        '</p>'+
                    '</div>'+
                '</div>').appendTo($("#appmarket_import_dialog_content"));

                $('<div class="row" id="appmarket_import_file_template">'+
                    '<div class="large-10 large-centered columns">'+
                        '<div class="large-10 columns">'+
                            '<label>'+
                                '<i class="fa fa-fw fa-file-text-o"/>&emsp;'+
                                tr("Template Name")+
                            '</label>'+
                            '<input type="text" class="name" value="' + (appliance['opennebula_template']['NAME']||appliance['name']) +'" />'+
                        '</div>'+
                        '<div class="large-2 columns appmarket_template_result">'+
                        '</div>'+
                    '</div>'+
                    '<div class="large-10 large-centered columns appmarket_template_response">'+
                    '</div>'+
                '</div>').appendTo($("#appmarket_import_dialog_content"));
            }

            $appmarket_import_dialog.foundation().foundation('reveal', 'open');

            var images_information = [];

            $("#appmarket_import_form").submit(function(){
                function try_to_create_template(){
                    var images_created = $(".appmarket_image_result.success", $appmarket_import_dialog).length;
                    if ((images_created == number_of_files) && !template_created) {
                        template_created = true;

                        if (appliance['opennebula_template'] && appliance['opennebula_template'] !== "CPU=1") {
                            var vm_template
                            try {
                                vm_template = JSON.parse(appliance['opennebula_template'])
                            } catch (error) {
                                $(".appmarket_template_result", template_context).html('<span class="fa-stack fa-2x" style="color: #dfdfdf">'+
                                      '<i class="fa fa-cloud fa-stack-2x"></i>'+
                                      '<i class="fa  fa-warning fa-stack-1x fa-inverse"></i>'+
                                    '</span>');

                                $(".appmarket_template_response", template_context).html('<p style="font-size:12px" class="error-color">'+
                                      (error.message || tr("Cannot contact server: is it running and reachable?"))+
                                    '</p>');

                                $("input", template_context).removeAttr("disabled");
                                $("button", $appmarket_import_dialog).removeAttr("disabled");
                                template_created = false;
                                return;
                            }

                            if ($.isEmptyObject(vm_template.DISK))
                                vm_template.DISK = []
                            else if (!$.isArray(vm_template.DISK))
                                vm_template.DISK = [vm_template.DISK]

                            vm_template.NAME = $("input", template_context).val();
                            if (!vm_template.CPU)
                                vm_template.CPU = "1"
                            if (!vm_template.MEMORY)
                                vm_template.MEMORY = "1024"

                            $.each(images_information, function(image_index, image_info){
                                if (!vm_template.DISK[image_index]) {
                                    vm_template.DISK[image_index] = {}
                                }

                                vm_template.DISK[image_index].IMAGE = image_info.IMAGE.NAME;
                                vm_template.DISK[image_index].IMAGE_UNAME = image_info.IMAGE.UNAME;
                            })

                            vm_template.FROM_APP = appliance['_id']["$oid"];
                            vm_template.FROM_APP_NAME = appliance['name'];

                            OpenNebula.Template.create({
                                timeout: true,
                                data: {vmtemplate: vm_template},
                                success: function (request, response){
                                    $(".appmarket_template_result", template_context).addClass("success").html('<span class="fa-stack fa-2x" style="color: #dfdfdf">'+
                                          '<i class="fa fa-cloud fa-stack-2x"></i>'+
                                          '<i class="fa  fa-check fa-stack-1x fa-inverse"></i>'+
                                        '</span>');

                                    $(".appmarket_template_response", template_context).html('<p style="font-size:12px" class="running-color">'+
                                          tr("Template created successfully")+' ID:'+response.VMTEMPLATE.ID+
                                        '</p>');

                                    $("button", $appmarket_import_dialog).hide();
                                },
                                error: function (request, error_json){
                                    $(".appmarket_template_result", template_context).html('<span class="fa-stack fa-2x" style="color: #dfdfdf">'+
                                          '<i class="fa fa-cloud fa-stack-2x"></i>'+
                                          '<i class="fa  fa-warning fa-stack-1x fa-inverse"></i>'+
                                        '</span>');

                                    $(".appmarket_template_response", template_context).html('<p style="font-size:12px" class="error-color">'+
                                          (error_json.error.message || tr("Cannot contact server: is it running and reachable?"))+
                                        '</p>');

                                    $("input", template_context).removeAttr("disabled");
                                    $("button", $appmarket_import_dialog).removeAttr("disabled");
                                    template_created = false;
                                }
                            });
                        } else {
                            $("button", $appmarket_import_dialog).hide();
                        }
                    };
                }

                var number_of_files = appliance['files'].length;
                var template_created = false;

                $("input, button", $appmarket_import_dialog).attr("disabled", "disabled");
                $(".appmarket_image_result:not(.success)",  $appmarket_import_dialog).html('<span class="fa-stack fa-2x" style="color: #dfdfdf">'+
                      '<i class="fa fa-cloud fa-stack-2x"></i>'+
                      '<i class="fa  fa-spinner fa-spin fa-stack-1x fa-inverse"></i>'+
                    '</span>');
                $(".appmarket_template_result",  $appmarket_import_dialog).html('<span class="fa-stack fa-2x" style="color: #dfdfdf">'+
                      '<i class="fa fa-cloud fa-stack-2x"></i>'+
                      '<i class="fa  fa-spinner fa-spin fa-stack-1x fa-inverse"></i>'+
                    '</span>');

                var template_context = $("#appmarket_import_file_template",  $appmarket_import_dialog);

                $.each(appliance['files'], function(index, value){
                    var context = $("#appmarket_import_file_"+index,  $appmarket_import_dialog);

                    if ($(".appmarket_image_result:not(.success)", context).length > 0) {
                        img_obj = {
                            "image" : {
                                "NAME": $("input.name",context).val(),
                                "PATH": appliance['links']['download']['href']+'/'+index,
                                "TYPE": value['type'],
                                "MD5": value['md5'],
                                "SHA1": value['sha1'],
                                "TYPE": value['type'],
                                "DRIVER": value['driver'],
                                "DEV_PREFIX": value['dev_prefix'],
                                "FROM_APP": appliance['_id']["$oid"],
                                "FROM_APP_NAME": appliance['name'],
                                "FROM_APP_FILE": index
                            },
                            "ds_id" : $("#appmarket_img_datastore select", $appmarket_import_dialog).val()
                        };

                        OpenNebula.Image.create({
                            timeout: true,
                            data: img_obj,
                            success: function (file_index, file_context){
                                return function(request, response) {
                                    $(".appmarket_image_result", file_context).addClass("success").html('<span class="fa-stack fa-2x" style="color: #dfdfdf">'+
                                          '<i class="fa fa-cloud fa-stack-2x"></i>'+
                                          '<i class="fa  fa-check fa-stack-1x fa-inverse"></i>'+
                                        '</span>');

                                    $(".appmarket_image_response", file_context).html('<p style="font-size:12px" class="running-color">'+
                                          tr("Image created successfully")+' ID:'+response.IMAGE.ID+
                                        '</p>');

                                    images_information[file_index] = response;

                                    try_to_create_template();
                                };
                            }(index, context),
                            error: function (request, error_json){
                                $(".appmarket_template_result", template_context).html('');

                                $(".appmarket_image_result", context).html('<span class="fa-stack fa-2x" style="color: #dfdfdf">'+
                                      '<i class="fa fa-cloud fa-stack-2x"></i>'+
                                      '<i class="fa  fa-warning fa-stack-1x fa-inverse"></i>'+
                                    '</span>');

                                $(".appmarket_image_response", context).html('<p style="font-size:12px" class="error-color">'+
                                      (error_json.error.message || tr("Cannot contact server: is it running and reachable?"))+
                                    '</p>');

                                $("input", template_context).removeAttr("disabled");
                                $("input", context).removeAttr("disabled");
                                $("button", $appmarket_import_dialog).removeAttr("disabled");
                            }
                        });
                    }
                });

                try_to_create_template();

                return false;
            })
        },
        error: onError
    },

    "AppMarket.show" : {
        type: "single",
        call: AppMarket.show,
        callback: function(request, response) {
            updateMarketElement(request, response);
            if (Sunstone.rightInfoVisible($("#apptools-appmarket-appliances"))) {
                updateAppMarketInfo(request, response);
            }
        },
        error: onError
    },

    "AppMarket.showinfo" : {
        type: "single",
        call: AppMarket.show,
        callback: updateAppMarketInfo,
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
    "AppMarket.convert_dialog" : {
        type: "action",
        layout: "main",
        text: tr("Convert")
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
  '<div class="row">'+
    '<div class="large-12">'+
      '<h3 class="subheader">'+tr("Import Appliance")+'</h3>'+
    '</div>'+
  '</div>'+
  '<form id="appmarket_import_form">'+
      '<div id="appmarket_import_dialog_content">'+
      '</div>'+
      '<div class="form_buttons">'+
          '<button class="button radius right success" id="appmarket_import_button" type="submit">'+tr("Import")+'</button>'+
      '</div>'+
  '</form>'+
  '<a class="close-reveal-modal">&#215;</a>'+
'</div>';

var appmarket_convert_dialog =
'<div id="appmarket_convert_dialog">'+
  '<div class="row">'+
    '<div class="large-12">'+
      '<h3 class="subheader">'+tr("Convert Appliance")+'</h3>'+
    '</div>'+
  '</div>'+
  '<div class="row">'+
    '<div class="large-12">'+
        '<p>'+tr("Only appliances created from an OVA file can be converted to different formats")+'</p>'+
    '</div>'+
  '</div>'+
  '<div class="row">\
      <div class="large-12 columns">\
        <label for="format">'+tr("Format")+':</label>\
        <select name="format" id="format">\
            <option value=""></option>\
            <option value="qcow2">'+tr("qcow2")+'</option>\
            <option value="raw">'+tr("raw")+'</option>\
            <option value="vdi">'+tr("vdi")+'</option>\
            <option value="vmdk">'+tr("vmdk")+'</option>\
        </select>\
      </div>\
    </div>\
    <div class="row">\
      <div class="large-12 columns">\
        <input type="checkbox" name="delete_source" id="delete_source" />\
        <label class="inline" for="delete_source">'+tr("Delete original appliance")+':</label>\
      </div>\
    </div>\
    <div class="form_buttons">\
       <button class="button radius right success" id="convert_appliance_button" type="button">'+tr("Convert")+'</button>\
    </div>\
  <a class="close-reveal-modal">&#215;</a>\
</div>';

var file_section_create_from =
'<div class="row">\
  <div class="large-12 columns">\
    <fieldset>\
      <legend>File 0 <span class="tip">If an OVA url is provided this section will be ignored</span></legend>\
      <div class="row">\
        <div class="large-12 columns">\
          <label for="files.0.name">'+tr("File Name")+'\
            <span class="tip">'+tr("Name of the file. This will be used to register the Image in OpenNebula")+'</span>\
          </label>\
          <input type="text" name="files.0.name" id="files.0.name" />\
        </div>\
      </div>\
      <div class="row">\
        <div class="large-12 columns">\
          <label for="files.0.url">'+tr("URL")+'\
            <span class="tip">'+tr("URL of the file")+'</span>\
          </label>\
          <input type="text" name="files.0.url" id="files.0.url" />\
        </div>\
      </div>\
      <div class="row">\
        <div class="large-6 columns">\
          <label for="files.0.size">'+tr("Size")+'\
            <span class="tip">'+tr("Size of the file in bytes")+'</span>\
          </label>\
          <input type="text" name="files.0.size" id="files.0.size" />\
        </div>\
        <div class="large-6 columns">\
          <label for="files.0.compression">'+tr("Compression")+':</label>\
          <select name="files.0.compression" id="files.0.compression">\
              <option value=""></option>\
              <option value="bz2">'+tr("bz2")+'</option>\
              <option value="gzip">'+tr("gzip")+'</option>\
              <option value="none">'+tr("none")+'</option>\
          </select>\
        </div>\
      </div>\
      <div class="row">\
        <div class="large-6 columns">\
          <label for="files.0.md5">'+tr("MD5")+':</label>\
          <input type="text" name="files.0.md5" id="files.0.md5" />\
        </div>\
        <div class="large-6 columns">\
          <label for="files.0.sha1">'+tr("SHA1")+':</label>\
          <input type="text" name="files.0.sha1" id="files.0.sha1" />\
        </div>\
      </div>\
      <div class="row">\
        <div class="large-6 columns">\
          <label for="files.0.driver">'+tr("Driver")+
            '<span class="tip">'+tr("Specific image mapping driver. KVM: raw, qcow2. XEN: tap:aio, file:")+'</span>'+
          ':</label>\
          <input type="text" name="files.0.driver" id="files.0.driver" />\
        </div>\
        <div class="large-6 columns">\
          <label for="files.0.dev_prefix">'+tr("Dev Prefix")+
            '<span class="tip">'+tr("Prefix for the emulated device this image will be mounted at. For instance, “hd”, “sd”. If omitted, the default value is the one defined in oned.conf (installation default is “hd”).")+'</span>'+
         ':</label>\
          <input type="text" name="files.0.dev_prefix" id="files.0.dev_prefix" />\
        </div>\
      </div>\
    </fieldset>\
  </div>\
</div>';


var create_appconverter_appliance =
'<div class="row">\
  <div class="large-5 columns">\
    <h3 id="create_appconverter_appliance_header" class="subheader">'+tr("Create Appliance")+'</h3>\
    <h3 id="update_appconverter_appliance_header" class="subheader">'+tr("Update Appliance")+'</h3>\
  </div>\
  <div class="large-7 columns">\
    <dl class="tabs right" data-tab>\
        <dd class="active"><a href="#appliance_wizardTab">'+tr("Wizard")+'</a></dd>\
        <dd><a href="#appliance_rawTab">'+tr("Advanced mode")+'</a></dd>\
    </dl>\
  </div>\
</div>\
<div class="reveal-body">\
    <form id="create_appconverter_appliance" action="" class="custom creation">\
        <div class="tabs-content">\
            <div id="appliance_wizardTab" class="content  active">\
                <div class="row">\
                  <div class="large-6 columns">\
                    <label for="name">'+tr("Name")+'\
                      <span class="tip">'+tr("Name of the appliance")+'</span>\
                    </label>\
                    <input type="text" name="name" id="name" />\
                  </div>\
                  <div class="large-6 columns">\
                    <label for="short_description">'+tr("Short Description")+'\
                      <span class="tip">'+tr("This information will be shown in the list view")+'</span>\
                    </label>\
                    <input type="text" name="short_description" id="short_description" />\
                  </div>\
                </div>\
                <div class="row">\
                  <div class="large-6 columns">\
                    <label for="tags">'+tr("Tags")+'\
                      <span class="tip">'+tr("Comma-separated tags. Example: ubuntu,hpc,mysql")+'</span>\
                    </label>\
                    <input type="text" name="tags" id="tags" />\
                  </div>\
                  <div class="large-6 columns">\
                    <label for="description">'+tr("Description")+'\
                      <span class="tip">'+tr("This information will be shown in the detailed view. Markdown syntax is supported.")+'</span>\
                    </label>\
                    <textarea rows=5 type="text" name="description" id="description" />\
                  </div>\
                </div>\
                <br>\
                <div class="row">\
                  <div class="large-6 columns">\
                    <label for="catalog">'+tr("Catalog")+'\
                      <span class="tip">'+tr("If not provided the appliance will be included in the 'community' catalog. By default all users have access to the 'community' catalog, but each user can be granted with access to different catalogs. Comma-separated catalogs. Example: silver,gold.")+'</span>\
                    </label>\
                    <input type="text" name="catalog" id="catalog" />\
                  </div>\
                  <div class="large-6 columns">\
                    <label for="version">'+tr("Version")+'\
                      <span class="tip">'+tr("Appliance version")+'</span>\
                    </label>\
                    <input type="text" name="version" id="version" />\
                  </div>\
                </div>\
                <br>\
                <div class="row">\
                  <div class="large-6 columns">\
                        <label for="os-id">'+tr("OS ID")+'\
                          <span class="tip">'+tr("Example: Ubuntu")+'</span>\
                        </label>\
                        <input type="text" name="os-id" id="os-id" />\
                  </div>\
                  <div class="large-6 columns">\
                        <label for="hypervisor">'+tr("Hypervisor")+':</label>\
                        <select name="hypervisor" id="hypervisor">\
                            <option value=""></option>\
                            <option value="all">'+tr("all")+'</option>\
                            <option value="KVM">'+tr("KVM")+'</option>\
                            <option value="VMWARE">'+tr("VMWARE")+'</option>\
                            <option value="XEN">'+tr("XEN")+'</option>\
                        </select>\
                  </div>\
                </div>\
                <div class="row">\
                  <div class="large-6 columns">\
                        <label for="os-release">'+tr("OS Release")+'\
                          <span class="tip">'+tr("Example: 12.04")+'</span>\
                        </label>\
                        <input type="text" name="os-release" id="os-release" />\
                  </div>\
                  <div class="large-6 columns">\
                        <label for="img_target">'+tr("Format")+'\
                          <span class="tip">'+tr("Format of the appliance files")+'</span>\
                        </label>\
                        <select name="format" id="format">\
                            <option value=""></option>\
                            <option value="qcow2">'+tr("qcow2")+'</option>\
                            <option value="raw">'+tr("raw")+'</option>\
                            <option value="vdi">'+tr("vdi")+'</option>\
                            <option value="vmdk">'+tr("vmdk")+'</option>\
                        </select>\
                  </div>\
                </div>\
                <div class="row">\
                  <div class="large-6 columns">\
                        <label for="os-arch">'+tr("OS Arch")+'\
                          <span class="tip">'+tr("Example: x86_64")+'</span>\
                        </label>\
                        <input type="text" name="os-arch" id="os-arch" />\
                  </div>\
                  <div class="large-6 columns">\
                  </div>\
                </div>\
                <br>'+
                '<div class="row">'+
                  '<div class="large-12 columns text-center">'+
                    '<input id="app_radioImage" type="radio" name="source_type" value="ova" checked>'+
                        '<label for="app_radioImage">'+tr("OVA")+
                            '<span class="tip">'+tr("In this case you will need the AppMarket Worker component that will download, unpack and generate the files URLs and OpenNebula template. If there is no AppWarket Worker, appliances created providing an OVA url will stay in the init status, and will not be available to be donwloaded")+'</span>'+
                        '</label>'+
                    '<input id="app_radioVolatile" type="radio" name="source_type" value="">'+
                        '<label for="app_radioVolatile">'+tr("Files & Template")+
                            '<span class="tip">'+tr("In this case the files URLs and OpenNebula template have to be manually specified. The files will not be dowloaded, only the URLs will be stored")+'</span>'+
                        '</label>'+
                  '</div>'+
                '</div>'+
                '<div class="from_ova">'+
                  '<div class="row">\
                    <div class="large-12 columns">\
                      <label for="source">'+tr("OVA URL")+'\
                        <span></span>\
                      </label>\
                      <input type="text" name="source" id="source" />\
                    </div>\
                  </div>\
                </div>\
                <div class="from_files hidden">\
                    <div class="row">\
                      <div class="large-12 columns">\
                        <label for="opennebula_template">'+tr("OpenNebula Template")+'\
                          <span class="tip">'+tr("JSON format. If an OVA url is provided this field will be ignored")+'</span>\
                        </label>\
                        <textarea rows=5 type="text" name="opennebula_template" id="opennebula_template" />\
                      </div>\
                    </div>' +
                    file_section_create_from +
                    '<div id=more_files_appliance_create>\
                    </div>\
                    <br>\
                    <div class="row">\
                      <div class="large-12 columns">\
                        <button class="button radius right small" type="button" id="more_files_appliance_create_button">'+tr("Add another file")+'</button>\
                      </div>\
                    </div>\
                </div>\
                <div class="reveal-footer">\
                    <div class="form_buttons">\
                        <button class="button success radius right" id="create_appconverter_appliance_wizard" value="image/create">'+tr("Create")+'</button>\
                        <button class="button radius right" id="update_appconverter_appliance_wizard" value="image/create">'+tr("Update")+'</button>\
                        <button class="button secondary radius" id="create_appconverter_appliance_reset"  type="reset" value="reset">'+tr("Reset")+'</button>\
                    </div>\
                </div>\
            </div>\
            <div id="appliance_rawTab" class="content">\
                <textarea id="template" rows="15" style="width:100%; height: 300px"></textarea>\
                <div class="reveal-footer">\
                    <div class="form_buttons">\
                        <button class="button success radius right" id="create_appconverter_appliance_raw" value="image/create">'+tr("Create")+'</button>\
                        <button class="button radius right" id="update_appconverter_appliance_raw" value="image/create">'+tr("Update")+'</button>\
                        <button class="button secondary radius" id="create_appconverter_appliance_reset"  type="reset" value="reset">'+tr("Reset")+'</button>\
                    </div>\
                </div>\
            </div>\
        </div>\
        <a class="close-reveal-modal">&#215;</a>\
    </form>\
</div>';


var appmarketplace_tab = {
    title: "Appliances",
    buttons: appmarket_buttons,
    tabClass: 'subTab',
    parentTab: 'apptools-appmarket-dashboard',
    search_input: '<input id="appliances_search" type="text" placeholder="'+tr("Search")+'" />',
    list_header: '<i class="fa fa-fw fa-truck"></i>&emsp;'+tr("OpenNebula AppMarket"),
    info_header: '<i class="fa fa-fw fa-truck"></i>&emsp;'+tr("Appliance"),
    subheader: '',
    content:   '<div class="row" id="error_message" hidden>\
        <div class="small-6 columns small-centered text-center">\
            <div class="alert-box alert-box-error radius">'+tr("Cannot connect to AppMarket server")+'</div>\
        </div>\
    </div>',
    table: '<table id="datatable_appmarketplace" class="datatable twelve">\
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
      </table>'
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

$.fn.serializeObject = function()
{
    var o = {};
    var a = this.serializeArray();

    $.each(a, function() {
        if (this.value) {
            var str_array = this.name.split('.')
            var key = str_array[0]

            if (key == 'files'){
                var index = str_array[1]
                var file_key = str_array[2]

                if (!o[key]) {
                    o[key] = [];
                }

                if (!o[key][index]) {
                    o[key][index] = {};
                }

                o[key][index][file_key] = this.value;
            } else if (key == 'tags') {
              o[key] = this.value.split(',');
            } else if (key == 'catalogs') {
              o[key] = this.value.split(',');
            } else {
              o[key] = this.value;
            }
        }

    });

    return o;
};

function update_form_content(response, form) {
  var a = $(form).serializeArray();

  $.each(a, function() {
    var str_array = this.name.split('.')

    var element_id = "#" + str_array.join("\\.")

    if ($(element_id)[0]) {
      var value
      var key = str_array[0]

      if (key == 'files' && response[key]){
        var index = parseInt(str_array[1])
        var sec_key = str_array[2]

        value = response[key][index][sec_key]
      } else {
        value = response[str_array[0]]
      }

      if (value) {
        $(element_id, form).val(value);
      }
    }
  } )
}

function appmarketplaceElements(){
    return getSelectedNodes(dataTable_appmarket);
}

// Callback to add an service_template element
function addConverterApplianceElement(request, template_json){
    addElement(template_json,dataTable_appmarket);
}

function updateAppMarketInfo(request,app){
    var url = app.links.download.href;
    url = url.replace(/\/download$/, '');

    var files_table = '<table id="info_appmarketplace_table2" class="dataTable">\
         <thead>\
           <tr><th colspan="2">'+tr("Images")+'</th></tr>\
         </thead>\
         <tbody>';

    if (app['files']) {
        $.each(app['files'], function(index, value){
            files_table +=  '<tr>\
                      <td class="value_td">'+value['name']+'</td>\
                      <td class="value_td">'+humanize_size(value['size'], true)+'</td>\
                    </tr>'
        });
    } else {
        files_table +=  '<tr>\
                  <td colspan="2" class="value_td">'+tr("No Images defined")+'</td>\
                </tr>'
    }

    files_table += '</tbody>\
      </table>';

    var info_tab = {
        title : tr("Info"),
        icon: "fa-info-circle",
        content :
        '<div class="row">\
        <div class="large-6 columns">\
        <table id="info_appmarketplace_table" class="dataTable">\
            <thead>\
              <tr><th colspan="2">'+tr("Information")+'</th></tr>\
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
                <td class="key_td">' + tr("URL") + '</td>\
                <td class="value_td"><a href="'+url+'" target="_blank">'+tr("link")+'</a></td>\
              </tr>\
              <tr>\
                <td class="key_td">' + tr("Publisher") + '</td>\
                <td class="value_td">'+app['publisher']+'</td>\
              </tr>\
              <tr>\
                <td class="key_td">' + tr("Downloads") + '</td>\
                <td class="value_td">'+app['downloads']+'</td>'+
              (app['status'] ? '<tr>\
                <td class="key_td">' + tr("Status") + '</td>\
                <td class="value_td">'+app['status']+'</td>\
              </tr>' : '') +
              (app['tags'] ? '<tr>\
                <td class="key_td">' + tr("Tags") + '</td>\
                <td class="value_td">'+app['tags'].join(' ')+'</td>\
              </tr>' : '') +
              (app['catalog'] ? '<tr>\
                <td class="key_td">' + tr("Catalog") + '</td>\
                <td class="value_td">'+app['catalog']+'</td>\
              </tr>' : '') +
              '<tr>\
                <td class="key_td">' + tr("OS") + '</td>\
                <td class="value_td">'+app['os-id']+' '+app['os-release']+'</td>\
              </tr>\
              <tr>\
                <td class="key_td">' + tr("Arch") + '</td>\
                <td class="value_td">'+app['os-arch']+'</td>\
              </tr>' +
              (app['files'] ? '<tr>\
                <td class="key_td">' + tr("Size") + '</td>\
                <td class="value_td">'+humanize_size(app['files'][0]['size'],true)+'</td>\
              </tr>' : '') +
              '<tr>\
                <td class="key_td">' + tr("Hypervisor") + '</td>\
                <td class="value_td">'+app['hypervisor']+'</td>\
              </tr>\
              <tr>\
                <td class="key_td">' + tr("Format") + '</td>\
                <td class="value_td">'+app['format']+'</td>\
              </tr>' +
            '</tbody>\
        </table>\
        </div>\
        <div class="large-6 columns">'+
          (app['short_description'] ? '<table class="dataTable">\
             <thead>\
               <tr><th colspan="2">'+tr("Short Description")+'</th></tr>\
             </thead>\
             <tbody>\
                <tr>\
                  <td class="value_td">'+app['short_description'].replace(/\n/g, "<br />")+'</td>\
                </tr>\
              </tbody>\
          </table>' : '') +
          '<table id="info_appmarketplace_table2" class="dataTable">\
             <thead>\
               <tr><th colspan="2">'+tr("Description")+'</th></tr>\
             </thead>\
             <tbody>\
                <tr>\
                  <td class="value_td">'+app['description'].replace(/\n/g, "<br />")+'</td>\
                </tr>\
              </tbody>\
          </table>'+
          files_table+
          (app['opennebula_template'] ? '<table class="dataTable">\
             <thead>\
               <tr><th colspan="2">'+tr("OpenNebula Template")+'</th></tr>\
             </thead>\
             <tbody>\
                <tr>\
                  <td class="value_td">'+app['opennebula_template'].replace(/\n/g, "<br />")+'</td>\
                </tr>\
              </tbody>\
          </table>' : '') +
        '</div>\
      </div>'
    };

    var jobs_tab = {
        title: tr("Jobs"),
        icon: "fa-cogs",
        content : '<div id="job_actions" class="row">\
            <div class="action_blocks large-12 columns">\
            </div>\
          </div>\
          <div class="row">\
            <div class="large-12 columns">\
              <table id="datatable_appconverter_job" class="dataTable">\
                <thead>\
                  <tr>\
                    <th class="check"></th>\
                    <th>'+tr("ID")+'</th>\
                    <th>'+tr("Name")+'</th>\
                    <th>'+tr("Status")+'</th>\
                    <th>'+tr("Worker")+'</th>\
                    <th>'+tr("Appliance")+'</th>\
                    <th>'+tr("Created")+'</th>\
                    <th>'+tr("Error")+'</th>\
                  </tr>\
                </thead>\
                <tbody id="tbodyappconverter_job">\
                </tbody>\
              </table>\
            </div>\
        </div>'
    }

    var template_tab = {
        title: tr("Template"),
        icon: "fa-file-o",
        content : '<div class="row">\
          <div class="large-12 columns">\
            <table id="template_template_table" class="info_table dataTable" style="width:80%">'+
            prettyPrintJSON(app)+'\
            </table>\
          </div>\
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
              "sWidth" : "60px"
            },
            { "mData": "_id.$oid", "sWidth" : "200px" },
            { "mData": "name" },
            { "mData": "status" },
            { "mData": "worker_host", "sDefaultContent" : "-" },
            { "mData": "appliance_id", "sDefaultContent" : "-" },
            { "mData": function (source) {
              return pretty_time(source.creation_time)
            }},
            { "mData": "error_message", "sDefaultContent" : "-" }
          ],
          "aoColumnDefs": [
            //{ "bVisible": true, "aTargets": Config.tabTableColumns(tab_name)},
            { "bVisible": false, "aTargets": [1, 5]}
        ]
    });

    insertButtonsInTab("apptools-appmarket-appliances", "appmarketplace_jobs_tab", job_buttons, $('#job_actions'))

    $('tbody input.check_item',dataTable_appconverter_jobs).die();
    $('tbody tr',dataTable_appconverter_jobs).die();

    initCheckAllBoxes(dataTable_appconverter_jobs, $('#job_actions'));
    tableCheckboxesListener(dataTable_appconverter_jobs, $('#job_actions'));

    var last_selected_row_job;

    $('tbody tr',dataTable_appconverter_jobs).die()
    $('tbody tr',dataTable_appconverter_jobs).live("click",function(e){
        if ($(e.target).is('input') ||
            $(e.target).is('select') ||
            $(e.target).is('option')) return true;

        if (e.ctrlKey || e.metaKey || $(e.target).is('input'))
        {
            $('.check_item',this).trigger('click');
        }
        else
        {
            var aData = dataTable_appconverter_jobs.fnGetData(this);
            var job_name = $(aData[0]).val();

            $('tbody input.check_item',$(this).parents('table')).removeAttr('checked');
            $('.check_item',this).click();
            $('td',$(this).parents('table')).removeClass('markrowchecked');

            if(last_selected_row_job) {
                last_selected_row_job.children().each(function(){
                    $(this).removeClass('markrowselected');
                });
            }

            last_selected_row_job = $(this);
            $(this).children().each(function(){
                $(this).addClass('markrowselected');
            });
        }
    });

    Sunstone.runAction('Job.list');

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

      if (e.ctrlKey || e.metaKey || $(e.target).is('input')) {
          $('.check_item',this).trigger('click');
      } else {
          var context = $(this).parents(".tab");
          popDialogLoading();
          Sunstone.runAction("AppMarket.show",id);
          $(".resource-id", context).html(id);
          $('.top_button, .list_button', context).attr('disabled', false);
      }

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

function updateMarketElement(request, app_json) {
  $.each(dataTable_appmarket.fnGetData(), function(index, data){
    if (data["_id"]["$oid"] === app_json["_id"]["$oid"]) {
      dataTable_appmarket.fnUpdate(app_json, index, undefined);
      return;
    }
  });
}

function deleteMarketElement(request) {
  var tab = dataTable_appmarket.parents(".tab");
  if (Sunstone.rightInfoVisible(tab)) {
      $("a[href='back']", tab).click();
  }

  $.each(dataTable_appmarket.fnGetData(), function(index, data){
    if (data["_id"]["$oid"] == request.request.data[0]) {
      dataTable_appmarket.fnDeleteRow(index);
      recountCheckboxes(dataTable_appmarket);
      return;
    }
  });
}

// Prepare the image creation dialog
function setupCreateConverterApplianceDialog(){
    dialogs_context.append('<div id="create_converter_appliance_dialog"></div>');
    $create_converter_appliance_dialog =  $('#create_converter_appliance_dialog',dialogs_context);

    var dialog = $create_converter_appliance_dialog;
    dialog.html(create_appconverter_appliance);

    setupTips($create_converter_appliance_dialog);

    dialog.addClass("reveal-modal medium max-height").attr("data-reveal", "");

    $('.advanced',dialog).hide();

    $('#advanced_appliance_create',dialog).click(function(){
        $('.advanced',dialog).toggle();
        return false;
    });

    $('input[name="source_type"]', dialog).change(function(){
      if (this.value == "ova") {
        $(".from_ova", dialog).toggle();
        $(".from_files", dialog).hide();
      } else {
        $(".from_ova", dialog).hide();
        $(".from_files", dialog).toggle();
      }
    })

    $('#create_appconverter_appliance_raw',dialog).click(function(){
        var template=$('#template',dialog).val();
        Sunstone.runAction("AppMarket.create",JSON.parse(template));
        return false;
    });

    $('#update_appconverter_appliance_raw',dialog).click(function(){
        var template=$('#template',dialog).val();
        Sunstone.runAction("AppMarket.update", appliance_update_id, template);
        return false;
    });

    $('#create_appconverter_appliance_reset', dialog).click(function(){
        $create_converter_appliance_dialog.html("");
        setupCreateConverterApplianceDialog();

        popUpCreateApplianceDialog();
    });

    $('#create_appconverter_appliance_wizard',dialog).click(function(){
        Sunstone.runAction("AppMarket.create", $("#create_appconverter_appliance").serializeObject());
        return false;
    });

    $('#update_appconverter_appliance_wizard',dialog).click(function(){
        Sunstone.runAction(
            "AppMarket.update",
            appliance_update_id,
            JSON.stringify($("#create_appconverter_appliance").serializeObject()));
        return false;
    });

    var file_index = 0;
    $("#more_files_appliance_create_button", dialog).click(function(){
        file_index++;
        setupTips($("#more_files_appliance_create").append(
            file_section_create_from.replace(/0/g,file_index)));
        return false;
    });
}

function popUpCreateApplianceDialog(){
    var dialog = $create_converter_appliance_dialog;

    $("#create_appconverter_appliance_header", dialog).show();
    $("#update_appconverter_appliance_header", dialog).hide();
    $("#create_appconverter_appliance_raw", dialog).show();
    $("#update_appconverter_appliance_raw", dialog).hide();
    $("#create_appconverter_appliance_wizard", dialog).show();
    $("#update_appconverter_appliance_wizard", dialog).hide();

    $create_converter_appliance_dialog.foundation().foundation('reveal', 'open');
}

function popUpConvertApplianceDialog(){
    if ($appmarket_convert_dialog != undefined) {
      $appmarket_convert_dialog.remove();
    }

    dialogs_context.append(appmarket_convert_dialog);
    $appmarket_convert_dialog = $('#appmarket_convert_dialog',dialogs_context);
    $appmarket_convert_dialog.addClass("reveal-modal").attr("data-reveal", "");

    $("#convert_appliance_button", $appmarket_convert_dialog).click(function(){
        var extra_info = {};
        extra_info['format'] = $('#format', $appmarket_convert_dialog).val()
        extra_info['delete_source'] = $("#delete_source", $appmarket_convert_dialog).is(":checked") ? true : false

        var data = {'params': extra_info}

        $.each(getSelectedNodes(dataTable_appmarket), function(index, elem) {
            Sunstone.runAction("AppMarket.convert", elem, data);
        });

        $appmarket_convert_dialog.foundation('reveal', 'close');

        return false;
    });

    $appmarket_convert_dialog.foundation().foundation('reveal', 'open');
}

function popUpUpdateApplianceDialog(){
    var selected_nodes = getSelectedNodes(dataTable_appmarket);
    if ( selected_nodes.length != 1 ) {
      notifyMessage("Please select one (and just one) appliance to update.");
      return false;
    }

    $create_converter_appliance_dialog.html("");
    setupCreateConverterApplianceDialog();
    var dialog = $create_converter_appliance_dialog;

    var appliance_id = ""+selected_nodes[0];
    Sunstone.runAction("AppMarket.show_to_update", appliance_id);

    $("#create_appconverter_appliance_header", dialog).hide();
    $("#update_appconverter_appliance_header", dialog).show();
    $("#create_appconverter_appliance_raw", dialog).hide();
    $("#update_appconverter_appliance_raw", dialog).show();
    $("#create_appconverter_appliance_wizard", dialog).hide();
    $("#update_appconverter_appliance_wizard", dialog).show();

    $create_converter_appliance_dialog.foundation().foundation('reveal', 'open');
}

function fillUpUpdateApplianceDialog(request, response){
    var template_json = response;
    delete template_json["_id"];
    delete template_json["downloads"];
    delete template_json["visits"];
    delete template_json["status"];

    if (template_json.files) {
        $("#advanced_appliance_create", $("#create_appconverter_appliance")).click();
        $.each(template_json.files, function(index, value){
          if (index !== 0)
            $("#more_files_appliance_create_button", $("#create_appconverter_appliance")).click();
        })
    }

    update_form_content(template_json, "#create_appconverter_appliance");

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
              { "mData": "files.0.hypervisor", "sWidth" : "100px", "sDefaultContent" : "-" },
              { "mData": "files.0.os-arch", "sWidth" : "100px", "sDefaultContent" : "-" },
              { "mData": "files.0.format", "sWidth" : "100px", "sDefaultContent" : "-" },
              { "mData": "tags"},
              { "mData": function (source) {
                return (source.creation_time ? pretty_time(source.creation_time) : '-')
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
      //onlyOneCheckboxListener(dataTable_appmarket);

      infoListenerAppMarket(dataTable_appmarket);

      Sunstone.runAction('AppMarket.list');

      setupCreateConverterApplianceDialog();
  }
});
