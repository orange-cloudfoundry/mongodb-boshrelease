#!/usr/bin/env bash 

set -e

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

if cf service ${DEPLOYMENT_NAME}-instance 1>/dev/null
then
	if [ $(cf service ${DEPLOYMENT_NAME}-instance|grep "There are no bound apps for this service"|wc -l) -eq 0 ]
	then
		for app in $(cf services|grep "^${DEPLOYMENT_NAME}-instance"|awk '{print $4}')
		do
			cf unbind-service ${app} ${DEPLOYMENT_NAME}-instance
		    cf delete -f ${APP_NAME}	
		done
	fi
	cf delete-service -f ${DEPLOYMENT_NAME}-instance
fi

cf delete-service-broker -f broker-${DEPLOYMENT_NAME}

