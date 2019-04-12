#!/usr/bin/env sh 

set -ex

if [ "${SKIP_SSL}" == "true" ]
then
    opts="${opts} --skip-ssl-validation"
fi



cf api ${CF_API_URL} ${opts}
cf login -u admin -p ${CF_ADMIN_PASSWORD}

cf delete-service-broker mongodb -f

cf create-service-broker mongodb \
            mongodb-broker $(cat broker-password/password.txt) \
            http://mongodb-broker-mongodb-ci-deployment.$(echo ${CF_API_URL}|cut -d"/" -f3|cut -d"." -f2-) --space-scoped

