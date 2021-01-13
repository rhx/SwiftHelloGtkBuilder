#!/bin/sh
#
# Remove the .build folder
#
. ./config.sh
exec rm -rf .build ${BUILD_DIR}
