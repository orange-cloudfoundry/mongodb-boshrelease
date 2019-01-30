#!/usr/bin/env sh

set -ex

export BOSH_CONFIG=$PWD/bosh-director-config/bosh_config.yml

ROOT_FOLDER=${PWD}

cat ${ROOT_FOLDER}/deployment-specs/keyval.properties \
  | grep -v -E "^UPDATED|^UUID" \
  > ${ROOT_FOLDER}/deployment-specs/sourced.properties

source ${ROOT_FOLDER}/deployment-specs/sourced.properties 

if [ "${STEMCELL_TYPE}" != "centos" ]
then
  STEMCELL_TYPE="ubuntu"   
fi

CI_IP=`echo ${ips} \
	| sed -e "s/,/:${PORT},/g" -e "s/$/:${PORT}/"`

# testing if we are using ssl
mongo_cmd="mongo \"mongodb://${CI_IP}/?replicaSet=rs0\" -u ${USER} -p \"${password}\" --authenticationDatabase admin"

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

needed_version=$(grep "^mongodb" ${ROOT_FOLDER}/versions/keyval.properties|cut -d"=" -f2)

if [ "${installed_version}" != "${needed_version}" ] 
then
	echo "Mongodb server version is ${installed_version} and don\'t match expected one (${needed_version})"
  exit 666
fi
