#!/bin/bash

#------------------------------------------------------------------------------#
# Copyright 2002-2014, OpenNebula Project (OpenNebula.org), OpenNebula Systems #
#                                                                              #
# Licensed under the Apache License, Version 2.0 (the "License"); you may      #
# not use this file except in compliance with the License. You may obtain      #
# a copy of the License at                                                     #
#                                                                              #
# http://www.apache.org/licenses/LICENSE-2.0                                   #
#                                                                              #
# Unless required by applicable law or agreed to in writing, software          #
# distributed under the License is distributed on an "AS IS" BASIS,            #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.     #
# See the License for the specific language governing permissions and          #
# limitations under the License.                                               #
#------------------------------------------------------------------------------#

export VERSION=${VERSION:-2.0.3}
export SCRIPTS_DIR=$(cd `dirname $0`; pwd)/packages

rm -rf  $SCRIPTS_DIR; mkdir -p $SCRIPTS_DIR

PACKAGE_TYPE=rpm ./gen_package.sh
PACKAGE_TYPE=deb ./gen_package.sh
PACKAGE_TYPE=rpm ./gen_package.sh worker
PACKAGE_TYPE=deb ./gen_package.sh worker
