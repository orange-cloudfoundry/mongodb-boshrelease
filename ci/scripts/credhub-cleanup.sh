#!/usr/bin/env sh 

set -e

ROOT_FOLDER=${PWD}

echo "${CREDHUB_CA}" >/tmp/credhub_ca
echo "${UAA_CA}" >/tmp/uaa_ca

credhub api ${IP}:${PORT} --ca-cert /tmp/credhub_ca --ca-cert /tmp/uaa_ca
credhub login -u ${USER} -p ${PASSWORD}

credhub f -n /${BOSH_ALIAS}/${DEPLOYMENT_NAME}/${VAR} -j \
	| jq -r '.credentials[].name|select(contains("/'${DEPLOYMENT_NAME}'/"))' \
	| xargs -i credhub d -n {}
