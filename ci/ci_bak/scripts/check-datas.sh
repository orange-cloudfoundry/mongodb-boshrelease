#!/usr/bin/env sh

set -e

export BOSH_CONFIG=$PWD/bosh-director-config/bosh_config.yml

ROOT_FOLDER=${PWD}

cat ${ROOT_FOLDER}/deployment-specs/keyval.properties \
  | grep -v -E "^UPDATED|^UUID" \
  > ${ROOT_FOLDER}/deployment-specs/sourced.properties

source ${ROOT_FOLDER}/deployment-specs/sourced.properties 

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


cat ${ROOT_FOLDER}/datas/keyval.properties| grep -v -E "^UPDATED|^UUID" |tr -s '=' ' '|while read x y
do
	mongo_query="if (db.${COLLECTION}.find({x:$x,y:$y}).count() == 0)
 				{
 					throw new Error('values (x:$x,y:$y) not found in collection');
 				}"
 				
	eval "${mongo_cmd}" --eval \""${mongo_query}"\" --quiet
done