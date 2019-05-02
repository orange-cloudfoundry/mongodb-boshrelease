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

cd mongodb-bosh-release/src/cf-mongodb-example-app

cf push
