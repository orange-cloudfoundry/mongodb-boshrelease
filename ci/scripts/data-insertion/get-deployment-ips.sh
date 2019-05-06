#!/usr/bin/env bash 

set -e

apt-get install -qqy jq

export ROOT_FOLDER=${PWD}

export BOSH_CONFIG=$PWD/bosh-director-config/bosh_config.yml

pushd output || exit 666

[ -d ${ROOT_FOLDER}/deployment-specs ] && cp -rp ${ROOT_FOLDER}/deployment-specs/* .

# In a shard configuration, only indicate the mongos ips
bosh -e ${ALIAS} -d ${DEPLOYMENT_NAME} instances --ps --json \
	|jq -r '.Tables[].Rows[]|select((.process|contains("routing_service")) or (.process|contains("mongodb_server")))|.instance' \
	|xargs -i sh -c 'bosh -e '${ALIAS}' -d '${DEPLOYMENT_NAME}'  vms --json|jq -r ".Tables[].Rows[]|select(.instance|contains(\"$1\"))|.ips"' {} {} \
	|sort -u \
	|tr -s '\n' ','\
	|sed -e 's/,$//g' -e 's/^/ips=\"/' -e 's/$/\"/' \
	>> keyval.properties

echo $?	

#bosh -e ${ALIAS} -d ${DEPLOYMENT_NAME} vms --column Ips | sed -e 's/[[:space:]]*$/,/g' \
#			|tr -d "\n" \
#			|sed -e 's/,$//' -e 's/^/ips=\"/' -e 's/$/\"/' \
#			>> keyval.properties

popd