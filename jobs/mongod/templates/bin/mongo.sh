#!/bin/bash

set -e # exit immediately if a simple command exits with a non-zero status.
set -u # report the usage of uninitialized variables.

source `dirname $(readlink -f $0)`/setenv

export PARAM="$@"

pushd /var/vcap/packages/mongodb/bin >/dev/null
su -m vcap -c 'HOME=/home/vcap;'${MONGODB_BIN}'/mongo $PARAM'
popd >/dev/null
exit 0
