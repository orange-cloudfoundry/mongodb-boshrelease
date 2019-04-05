#!/usr/bin/env sh 

set -ex


#unset http_proxy https_proxy no_proxy

export http_proxy=http://minio.dbsp.dw:3128
export https_proxy=http://minio.dbsp.dw:3128

if [ "${USE_BOSH_LITE}" == "true" ]
then
	echo "${JUMPBOX_KEY}" > /tmp/jumpbox.key
	chmod 600 /tmp/jumpbox.key
	sshuttle -D -r jumpbox@${BOSH_IP} -e 'ssh -i /tmp/jumpbox.key -o ServerAliveInterval=60 -o ExitOnForwardFailure=yes -o StrictHostKeyChecking=no' 10.244.0.0/16 --dns --pidfile=/var/run/sshuttle-bosh-lite.pid
	#sleep 5
fi


if [ "${SKIP_SSL}" == "true" ]
then
    opts="${opts} --skip-ssl-validation"
fi

cf api ${CF_API_URL} ${opts}
cf login -u admin -p ${CF_ADMIN_PASSWORD}

cf create-service-broker mongodb \
            mongodb-broker $(cat broker-password/password.txt) \
            http://mongodb-broker-mongodb-ci-deployment.cf.dbsp.dw --space-scoped

[[ -f /var/run/sshuttle-bosh-lite.pid ]] && kill $(cat /var/run/sshuttle-bosh-lite.pid)            
