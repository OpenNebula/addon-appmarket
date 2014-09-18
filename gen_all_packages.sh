#!/bin/bash

export VERSION=${VERSION:-2.0.2}
export SCRIPTS_DIR=$(cd `dirname $0`; pwd)/packages

rm -rf  $SCRIPTS_DIR; mkdir -p $SCRIPTS_DIR

PACKAGE_TYPE=rpm ./gen_package.sh
PACKAGE_TYPE=deb ./gen_package.sh
PACKAGE_TYPE=rpm ./gen_package.sh worker
PACKAGE_TYPE=deb ./gen_package.sh worker
