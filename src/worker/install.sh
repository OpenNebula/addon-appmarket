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

ARGS=$*

usage() {
 echo
 echo "Usage: install.sh [-u install_user] [-g install_group]"
 echo "                  [-d ONE_LOCATION] [-l] [-h]"
 echo
 echo "-d: target installation directory, if not defined it'd be root. Must be"
 echo "    an absolute path. Installation will be selfcontained"
 echo "-l: creates symlinks instead of copying files, useful for development"
 echo "-h: prints this help"
}

PARAMETERS="hlu:g:d:"

if [ $(getopt --version | tr -d " ") = "--" ]; then
    TEMP_OPT=`getopt $PARAMETERS "$@"`
else
    TEMP_OPT=`getopt -o $PARAMETERS -n 'install.sh' -- "$@"`
fi

if [ $? != 0 ] ; then
    usage
    exit 1
fi

eval set -- "$TEMP_OPT"

LINK="no"
ONEADMIN_USER=`id -u`
ONEADMIN_GROUP=`id -g`
SRC_DIR=$PWD

while true ; do
    case "$1" in
        -h) usage; exit 0;;
        -d) ROOT="$2" ; shift 2 ;;
        -l) LINK="yes" ; shift ;;
        -u) ONEADMIN_USER="$2" ; shift 2;;
        -g) ONEADMIN_GROUP="$2"; shift 2;;
        --) shift ; break ;;
        *)  usage; exit 1 ;;
    esac
done

export ROOT

if [ -z "$ROOT" ]; then
    LIB_LOCATION="/usr/lib/one/ruby"
    BIN_LOCATION="/usr/bin"
    PACKAGES_LOCATION="/usr/share/one"
    SHARE_LOCATION="/usr/share/one"
    ETC_LOCATION="/etc/one"
    SUNSTONE_LOCATION="/usr/lib/one/sunstone"
else
    LIB_LOCATION="$ROOT/lib/ruby"
    BIN_LOCATION="$ROOT/bin"
    PACKAGES_LOCATION="$ROOT/share"
    SHARE_LOCATION="$ROOT/share"
    ETC_LOCATION="$ROOT/etc"
    SUNSTONE_LOCATION="$ROOT/lib/sunstone"
fi

do_file() {
    if [ "$UNINSTALL" = "yes" ]; then
        rm $2/`basename $1`
    else
        if [ "$LINK" = "yes" ]; then
            ln -fs $SRC_DIR/$1 $2
        else
            cp -R $SRC_DIR/$1 $2
        fi
    fi
}

copy_files() {
    FILES=$1
    DST=$DESTDIR$2

    mkdir -p $DST

    for f in $FILES; do
        do_file $f $DST
    done
}

create_dirs() {
    DIRS=$*

    for d in $DIRS; do
        dir=$DESTDIR$d
        mkdir -p $dir
    done
}

change_ownership() {
    DIRS=$*
    for d in $DIRS; do
        chown -R $ONEADMIN_USER:$ONEADMIN_GROUP $DESTDIR$d
    done
}

(

## Client files
#copy_files "client/lib/*" "$LIB_LOCATION/market"
#copy_files "client/bin/*" "$BIN_LOCATION"

## Server files

# bin
copy_files "bin/*" "$BIN_LOCATION"

# dirs containing files
copy_files "drivers" "$LIB_LOCATION/appconverter"
copy_files "lib" "$LIB_LOCATION/appconverter"

# files
copy_files "appconverter-worker.rb" "$LIB_LOCATION/appconverter"

# Sunstone
#copy_files "sunstone/public/js/*" "$SUNSTONE_LOCATION/public/js/plugins"
#copy_files "sunstone/public/images/*" "$SUNSTONE_LOCATION/public/images"
#copy_files "sunstone/routes/*" "$SUNSTONE_LOCATION/routes"

# version
#copy_files "version.rb" "$LIB_LOCATION"

# Do not link the ETC files
LINK="no"
copy_files "etc/appconverter-worker.conf" "$ETC_LOCATION"

)

#if [ -z "$NOPOSTINSTALL" ]; then
#    ./postinstall
#fi

