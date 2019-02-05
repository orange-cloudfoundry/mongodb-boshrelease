#!/usr/bin/env bash 

set -ex

if [ "${SKIP_SSL}" == "true" ]
then
    opts="${opts} --skip-ssl-validation"
fi

cf api ${CF_API_URL} ${opts}
cf login -u admin -p ${CF_ADMIN_PASSWORD}


if cf app mongodb-example-app 1>/dev/null; then

	cf unbind-service mongodb-example-app mongodb-instance

	cf delete-service -f mongodb-instance

	cf delete -f mongodb-example-app
fi

cf delete-service-broker -f mongodb

