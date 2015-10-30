/* -------------------------------------------------------------------------- */
/* Copyright 2002-2015, OpenNebula Project, OpenNebula Systems                */
/*                                                                            */
/* Licensed under the Apache License, Version 2.0 (the "License"); you may    */
/* not use this file except in compliance with the License. You may obtain    */
/* a copy of the License at                                                   */
/*                                                                            */
/* http://www.apache.org/licenses/LICENSE-2.0                                 */
/*                                                                            */
/* Unless required by applicable law or agreed to in writing, software        */
/* distributed under the License is distributed on an "AS IS" BASIS,          */
/* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   */
/* See the License for the specific language governing permissions and        */
/* limitations under the License.                                             */
/* -------------------------------------------------------------------------- */

define(function(require) {
  /*
    DEPENDENCIES
   */

  var BaseFormPanel = require('utils/form-panels/form-panel');
  var Sunstone = require('sunstone');
  var Locale = require('utils/locale');
  var Tips = require('utils/tips');
  var TemplateUtils = require('utils/template-utils');

  /*
    TEMPLATES
   */

  var TemplateWizardHTML = require('hbs!./create/wizard');
  var TemplateAdvancedHTML = require('hbs!./create/advanced');
  var TemplateAppFileSectionHTML = require('hbs!./create/file_section');

  /*
    CONSTANTS
   */

  var FORM_PANEL_ID = require('./create/formPanelId');
  var TAB_ID = require('../tabId');

  /*
    CONSTRUCTOR
   */

  function FormPanel() {
    this.formPanelId = FORM_PANEL_ID;
    this.tabId = TAB_ID;
    this.actions = {
      'create': {
        'title': Locale.tr("Create Appliance"),
        'buttonText': Locale.tr("Create"),
        'resetButton': true
      },
      'update': {
        'title': Locale.tr("Update Appliance"),
        'buttonText': Locale.tr("Update"),
        'resetButton': false
      }
    };

    this.fileIndex = 0;

    BaseFormPanel.call(this);
  }

  FormPanel.FORM_PANEL_ID = FORM_PANEL_ID;
  FormPanel.prototype = Object.create(BaseFormPanel.prototype);
  FormPanel.prototype.constructor = FormPanel;
  FormPanel.prototype.htmlWizard = _htmlWizard;
  FormPanel.prototype.htmlAdvanced = _htmlAdvanced;
  FormPanel.prototype.setup = _setup;
  FormPanel.prototype.onShow = _onShow;
  FormPanel.prototype.submitWizard = _submitWizard;
  FormPanel.prototype.submitAdvanced = _submitAdvanced;
  FormPanel.prototype.fill = _fill;

  return FormPanel;

  /*
    FUNCTION DEFINITIONS
   */

  function _htmlWizard() {
    return TemplateWizardHTML({
      'formPanelId': this.formPanelId,
      'appFileSectionHTML': TemplateAppFileSectionHTML({'fileIndex': this.fileIndex})
    });
  }

  function _htmlAdvanced() {
    return TemplateAdvancedHTML({formPanelId: this.formPanelId});
  }

  function _setup(context) {
    var that = this;
    that.fileIndex = 0;
    Tips.setup(context);

    $("#more_files_appliance_create_button", context).click(function() {
      that.fileIndex++;
      Tips.setup($("#more_files_appliance_create").append(
        TemplateAppFileSectionHTML({'fileIndex': that.fileIndex})));
      return false;
    });
  }

  function _onShow(context) {
  }

  function _submitWizard(context) {
    var template = _serializeForm(context);
    if (this.action == "create") {
      Sunstone.runAction("AppMarket.create", template);
      return false;
    } else if (this.action == "update") {
      Sunstone.runAction("AppMarket.update",
                          this.resourceId,
                          JSON.stringify(template));
      return false;
    }
  }

  function _submitAdvanced(context) {
    var template = $('#template', context).val();
    if (this.action == "create") {
      Sunstone.runAction("AppMarket.create", JSON.parse(template));
      return false;

    } else if (this.action == "update") {
      Sunstone.runAction("AppMarket.update", this.resourceId, template);
      return false;
    }
  }

  function _fill(context, element) {
    this.resourceId = element["_id"]["$oid"];
    delete element["_id"];
    delete element["downloads"];
    delete element["visits"];
    delete element["status"];

    if (element.files) {
      $("#advanced_appliance_create", context).click();
      $.each(element.files, function(index, value) {
          if (index !== 0)
            $("#more_files_appliance_create_button", context).click();
        })
    }

    _fillForm($('#' + FORM_PANEL_ID + "Wizard", context), element);

    $('#template', context).val(JSON.stringify(element, undefined, 2));
  }

  function _serializeForm(context) {
    var o = {};
    //var a = context.serializeArray();

    $.each(context, function() {
      if (this.value) {
        var str_array = this.name.split('.')
        var key = str_array[0]

        if (key == 'files') {
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

  function _fillForm(context, element) {
    var a = context.serializeArray();
    $.each(a, function() {
      var str_array = this.name.split('.')

      var element_id = "#" + str_array.join("\\.")

      if ($(element_id)[0]) {
        var value
        var key = str_array[0]

        if (key == 'files' && element[key]) {
          var index = parseInt(str_array[1])
          var sec_key = str_array[2]

          value = element[key][index][sec_key]
        } else {
          value = element[str_array[0]]
        }

        if (value) {
          $(element_id, context).val(value);
        }
      }
    });
  }
});
