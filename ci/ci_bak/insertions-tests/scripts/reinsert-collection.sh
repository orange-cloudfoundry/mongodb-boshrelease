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


# remove collection before insertion
mongo_query='if (db.'${COLLECTION}'.exists()){db.'${COLLECTION}'.drop()}'
eval "${mongo_cmd}" --eval \""${mongo_query}"\"


cat ${ROOT_FOLDER}/datas/keyval.properties| grep -v -E "^UPDATED|^UUID" |tr -s '=' ' '|while read x y
do
	mongo_query="db.${COLLECTION}.insert( { x : ${x}, y : ${y} })"
	eval "${mongo_cmd}" --eval \""${mongo_query}"\" --quiet
done