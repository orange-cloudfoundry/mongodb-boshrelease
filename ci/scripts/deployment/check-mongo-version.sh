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

# testing if we are using ssl
mongo_cmd="mongo \"mongodb://${USER}:${password}@${CI_IP}/?replicaSet=rs0&authSource=admin\""

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

# get mongodb server version
mongo_cmd="${mongo_cmd} --eval \"db.version()\""

installed_version=$(eval ${mongo_cmd} |tail -1)

needed_version=$(cat ${ROOT_FOLDER}/deployed-version/keyval.properties | grep -v -E "^UPDATED|^UUID" |cut -d"=" -f2)


[[ -f /var/run/sshuttle-bosh-lite.pid ]] && kill $(cat /var/run/sshuttle-bosh-lite.pid)

if [ "${installed_version}" != "${needed_version}" ] 
then
  echo "Mongodb server version is ${installed_version} and don't match expected one (${needed_version})"
  exit 666
fi
