#!/bin/bash

set -e # exit immediately if a simple command exits with a non-zero status.
set -u # report the usage of uninitialized variables.

source `dirname $(readlink --canonicalize-existing $0)`/setenv

export PARAM="$@"

pushd /var/vcap/packages/mongodb/bin >/dev/null
su -m vcap -c 'HOME=/home/vcap;'${MONGODB_BIN}'/mongo --ssl \
  --sslCAFile /var/vcap/jobs/${JOB_NAME}/ssl/mongodb.ca \
  --sslPEMKeyFile /var/vcap/jobs/${JOB_NAME}/ssl/client.pem $PARAM'
popd >/dev/null
exit 0
