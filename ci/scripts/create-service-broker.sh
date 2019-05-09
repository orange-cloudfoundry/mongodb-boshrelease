#!/usr/bin/env sh 

set -ex

if [ "${SKIP_SSL}" == "true" ]
then
    opts="${opts} --skip-ssl-validation"
fi

# removing 8.8.8.8 from resolv.conf in a BOSH_LITE env                                                                                                                                                                                                                          
                                                                                                                                                                                                                                                                                
if [ "${USE_BOSH_LITE}" == "true" ]                                                                                                                                                                                                                                             
then                                                                                                                                                                                                                                                                            
        sed -e "/^nameserver 8.8.8.8/d" /etc/resolv.conf > /tmp/resolv.conf

        cat  /tmp/resolv.conf > /etc/resolv.conf
fi



cf api ${CF_API_URL} ${opts}
cf login -u admin -p ${CF_ADMIN_PASSWORD}

cf delete-service-broker broker-${DEPLOYMENT_NAME} -f

cf create-service-broker broker-${DEPLOYMENT_NAME} \
            mongodb-broker $(cat broker-password/password.txt) \
            http://mongodb-broker-${DEPLOYMENT_NAME}.$(echo ${CF_API_URL}|cut -d"/" -f3|cut -d"." -f2-) --space-scoped

