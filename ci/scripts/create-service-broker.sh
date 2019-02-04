#!/usr/bin/env bash 

set -ex

if [ "${SKIP_SSL}" == "true" ]
then
    opts="${opts} --skip-ssl-validation"
fi

cf api ${CF_API_URL} ${opts}
cf login -u admin -p ${CF_ADMIN_PASSWORD}

cf create-service-broker mongodb \
            mongodb-broker $(cat broker-password/password.txt) \
            http://mongodb-broker-mongodb-ci-deployment.cf.dbsp.dw --space-scoped
