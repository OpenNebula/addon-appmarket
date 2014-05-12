#!/bin/bash

# -------------------------------------------------------------------------- #
# Copyright 2002-2013, OpenNebula Project (OpenNebula.org), C12G Labs        #
#                                                                            #
# Licensed under the Apache License, Version 2.0 (the "License"); you may    #
# not use this file except in compliance with the License. You may obtain    #
# a copy of the License at                                                   #
#                                                                            #
# http://www.apache.org/licenses/LICENSE-2.0                                 #
#                                                                            #
# Unless required by applicable law or agreed to in writing, software        #
# distributed under the License is distributed on an "AS IS" BASIS,          #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   #
# See the License for the specific language governing permissions and        #
# limitations under the License.                                             #
#--------------------------------------------------------------------------- #

VERSION=${VERSION:-2.0.0}
MAINTAINER=${MAINTAINER:-C12G Labs <support@c12g.com>}
LICENSE=${LICENSE:-Apache}
VENDOR=${VENDOR:-C12G Labs}
DESC="
OpenNebula Apps is a group of tools for users and administrators of OpenNebula that simplifies and optimizes cloud application management.
"
DESCRIPTION=${DESCRIPTION:-$DESC}
PACKAGE_TYPE=${PACKAGE_TYPE:-deb}
URL=${URL:-https://github.com/OpenNebula/addon-appmarket}

if [ "$1" = "worker" ]; then
    PACKAGE_NAME=${PACKAGE_NAME:-appmarket-worker}
    cd src/worker
else
    PACKAGE_NAME=${PACKAGE_NAME:-appmarket}
fi

SCRIPTS_DIR=${SCRIPTS_DIR:-PWD}

NAME="${PACKAGE_NAME}_${VERSION}.${PACKAGE_TYPE}"
rm $NAME

export DESTDIR=$PWD/tmp

if [ "$(id -u)" = "0" ]; then
    FLAGS='-u oneadmin -g oneadmin'
fi

rm -rf $DESTDIR
mkdir $DESTDIR

./install.sh $FLAGS

cd tmp

fpm -n "$PACKAGE_NAME" -t "$PACKAGE_TYPE" -s dir --vendor "$VENDOR" \
    --license "$LICENSE" --description "$DESCRIPTION" --url "$URL" \
    -m "$MAINTAINER" -v "$VERSION" \
    -a all -p $SCRIPTS_DIR/$NAME *

echo $NAME
