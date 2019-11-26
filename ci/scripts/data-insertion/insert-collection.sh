#!/usr/bin/env bash

set -e

export BOSH_CONFIG=$PWD/bosh-director-config/bosh_config.yml

ROOT_FOLDER=${PWD}


# if mongodb deployment is realized on a bosh lite server, we need to open a tunnel to it in order to 
# reach the containers ips

if [ "${USE_BOSH_LITE}" == "true" ]
then
	echo "${JUMPBOX_KEY}" > /tmp/jumpbox.key
	chmod 600 /tmp/jumpbox.key
	sshuttle --daemon -r jumpbox@${BOSH_IP} -e 'ssh -i /tmp/jumpbox.key -o ServerAliveInterval=60 -o ExitOnForwardFailure=yes -o StrictHostKeyChecking=no'  --dns 10.244.0.0/16 --pidfile=/var/run/sshuttle-bosh-lite.pid
fi	

cat ${ROOT_FOLDER}/deployment-specs/keyval.properties \
  | grep -v -E "^UPDATED|^UUID" \
  > ${ROOT_FOLDER}/deployment-specs/sourced.properties

source ${ROOT_FOLDER}/deployment-specs/sourced.properties 

CI_IP=`echo ${ips} \
	 | sed -e "s/,/:${PORT},/g" -e "s/$/:${PORT}/"`


# Don t connect a replicaset on mongos
if [ ${SHARDED} == "true" ]
then
 	mongo_cmd="mongo \"mongodb://${USER}:${password}@${CI_IP}/?authSource=admin\""
else  	
	mongo_cmd="mongo \"mongodb://${USER}:${password}@${CI_IP}/?replicaSet=rs0&authSource=admin\""
fi

# testing if we are using ssl
if [ "${REQUIRE_SSL}" == "true" ]
then
    if [ "${CA_CERT}" != "" ] 
    then 
    	cat > /tmp/CA.crt <<-EOF
			${CA_CERT}
		EOF
	else
		echo "SSL certificate not set" && exit 666
	fi  
	mongo_cmd="${mongo_cmd} --ssl --sslCAFile /tmp/CA.crt"
fi

# remove collection before insertion

mongo_query='if (db.'${COLLECTION}'.exists()){db.'${COLLECTION}'.drop()}'
eval "${mongo_cmd}" --eval \""${mongo_query}"\"

mongo_query=$(echo 'for (var i = 1; i <= 5; i++) {
						db.'${COLLECTION}'.insert( { x : i, y : Math.floor(Math.random() * ((1000000 + 1) - 1)) + 1 } )
					}')
eval "${mongo_cmd}" --eval \""${mongo_query}"\"


cd ${ROOT_FOLDER}/datas || exit 666

mongo_query='db.'${COLLECTION}'.find({},{_id:0})'
eval "${mongo_cmd}" --eval \""${mongo_query}"\"	| grep "^{" | tr -d ' ' \
					| sed -e 's/.[^:]*:\([0-9]*\).[^:]*:\([0-9]*\).*/\1=\2/' \
					> keyval.properties

[[ -f /var/run/sshuttle-bosh-lite.pid ]] && kill $(cat /var/run/sshuttle-bosh-lite.pid)					