#!/usr/bin/env sh 

set -ex

ROOT_FOLDER=${PWD}

set +x
credhub api ${IP}:${PORT} --skip-tls-validation
( echo ${USER} ; echo ${PASSWORD} ) \
    | credhub login
set -x

if [ "${STEMCELL_TYPE}" == "centos" ]
then
    # If we are on a centos deployment, deloyment name will be suffixed
    DEPLOYMENT_NAME="${DEPLOYMENT_NAME}-centos"
fi

mkdir -p output
cd output || exit 666

credhub g -n /${BOSH_ALIAS}/${DEPLOYMENT_NAME}/${VAR} -j \
	| jq -r '.value' \
	| sed -e "s/^/password=/" \
	> keyval.properties