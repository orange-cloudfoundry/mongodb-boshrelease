#!/usr/bin/env bash 

set -ex

if [ "${SKIP_SSL}" == "true" ]
then
    opts="${opts} --skip-ssl-validation"
fi

cf api ${CF_API_URL} ${opts}
cf login -u admin -p ${CF_ADMIN_PASSWORD}

cf unbind-service mongodb-example-app mongodb-instance

cf delete-service -f mongodb-instance

cf delete -f mongodb-example-app

cf delete-service-broker -f mongodb

