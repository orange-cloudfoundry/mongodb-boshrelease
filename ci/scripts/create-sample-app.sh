#!/usr/bin/env sh 

set -ex

if [ "${SKIP_SSL}" == "true" ]
then
    opts="${opts} --skip-ssl-validation"
fi



cf api ${CF_API_URL} ${opts}
cf login -u admin -p ${CF_ADMIN_PASSWORD}

cd mongodb-bosh-release/src/cf-mongodb-example-app

cf push
