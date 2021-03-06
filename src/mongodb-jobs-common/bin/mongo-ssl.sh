#!/usr/bin/env bash

set -e # exit immediately if a simple command exits with a non-zero status.
set -u # report the usage of uninitialized variables.

source ${JOBS_COMMON_DIR}/bin/setenv ${JOB_NAME}

PARAM="$@"

pushd /var/vcap/packages/mongodb/bin >/dev/null
exec chpst -u vcap:vcap env HOME=/home/vcap ${MONGODB_BIN}/mongo --ssl \
  --sslCAFile /var/vcap/jobs/${JOB_NAME}/ssl/CA.crt \
  ${PARAM}

popd >/dev/null
exit 0
