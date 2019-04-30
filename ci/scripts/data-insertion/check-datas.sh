#!/usr/bin/env sh

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


cat ${ROOT_FOLDER}/datas/keyval.properties| grep -v -E "^UPDATED|^UUID" |tr -s '=' ' '|while read x y
do
	mongo_query="if (db.${COLLECTION}.find({x:$x,y:$y}).count() == 0)
 				{
 					throw new Error('values (x:$x,y:$y) not found in collection');
 				}"
 				
	eval "${mongo_cmd}" --eval \""${mongo_query}"\" --quiet
done

[[ -f /var/run/sshuttle-bosh-lite.pid ]] && kill $(cat /var/run/sshuttle-bosh-lite.pid)