#!/bin/bash

#------------------------------------------------------------------------------#
# Copyright 2002-2015, OpenNebula Project, OpenNebula Systems                  #
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

# Sunstone
copy_files "public/js/*" "$SUNSTONE_LOCATION/public/js/plugins"
copy_files "routes/*" "$SUNSTONE_LOCATION/routes"

# Do not link the ETC files
LINK="no"
copy_files "etc/sunstone-appconverter.conf" "$ETC_LOCATION"

# Postinstall

if [ -z "$ROOT" ]; then
    SUNSTONE_VIEWS_PATH="/etc/one/sunstone-views"
    SUNSTONE_SERVER="/etc/one/sunstone-server.conf"
else
    SUNSTONE_VIEWS_PATH="$ROOT/etc/sunstone-views"
    SUNSTONE_SERVER="$ROOT/etc/sunstone-server.conf"
fi

VIEW_FILES="admin.yaml user.yaml"

function make_backup() {
    file=$1
    backup="$1.$(date '+%s')"

    if [ -f "$file" ]; then
        cp "$file" "$backup"
    fi
}

function add_config() {
    name=$1
    text=$2
    config_file=$3

    test -f $config_file && ! grep -q -- "$name" $config_file  && echo "$text" >> $config_file
}

function add_view() {
    for f in $VIEW_FILES; do
        add_config "$1" "$2" "$SUNSTONE_VIEWS_PATH/$f"
    done
}

function add_server() {
    add_config "$1" "$2" "$SUNSTONE_SERVER"
}

# Configure sunstone-views.yaml and sunstone-server.conf

make_backup "$SUNSTONE_VIEWS"
make_backup "$SUNSTONE_SERVER"

# TODO Add to available tabs in sunstone-views.yaml
# TODO Add to enabled tabs in VIEW_FILES

add_view "appconverter-dashboard:" \
"    appconverter-dashboard:
        panel_tabs:
        table_columns:
        actions:"

add_view "appconverter-appliances:" \
"    appconverter-appliances:
        panel_tabs:
            appconverter_appliance_info_tab: true
        table_columns:
            - 0         # Checkbox
            - 1         # ID
            - 2         # Name
            - 3         # Status
            - 4         # Created
        actions:
            Appliance.refresh: true"

add_view "appconverter-jobs:" \
"    appconverter-jobs:
        panel_tabs:
            appconverter_job_info_tab: true
        table_columns:
            - 0         # Checkbox
            - 1         # ID
            - 2         # Name
            - 3         # Status
            - 4         # Worker
            - 5         # Appliance
            - 6         # Created
        actions:
            Appliance.refresh: true"

add_server "^:routes:" ":routes:"
add_server "- appconverter" "    - appconverter"
)


