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
  var Locale = require('utils/locale');

  var Buttons = {
    "AppMarket.refresh" : {
      type: "action",
      layout: "refresh",
      alwaysActive: true
    },
    "AppMarket.import" : {
      type: "action",
      layout: "main",
      text: Locale.tr('Import')
    },
    "AppMarket.create_dialog" : {
      type: "create_dialog",
      layout: "create"
    },
    "AppMarket.update_dialog" : {
      type: "action",
      layout: "main",
      text: Locale.tr("Update")
    },
//    "AppMarket.convert_dialog" : {
//      type: "action",
//      layout: "main",
//      text: tr("Convert")
//    },
    "AppMarket.delete" : {
      type: "confirm",
      text: Locale.tr("Delete"),
      layout: "del",
      tip: Locale.tr("This will delete the selected appliances")
    }
  };

  return Buttons;
});
