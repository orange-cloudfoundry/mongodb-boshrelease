#!/usr/bin/env sh 

set -e

ROOT_FOLDER=${PWD}

export CREDHUB_CA_CERT=$(echo "${UAA_CA_CERT}${CA_CERT}")

credhub api ${IP}:${PORT}
( echo ${USER} ; echo ${PASSWORD} ) \
    | credhub login

mkdir -p output
cd output || exit 666

credhub g -n /${BOSH_ALIAS}/${DEPLOYMENT_NAME}/${VAR} -j \
	| jq -r '.value' \
	| sed -e "s/^/password=/" \
	> keyval.properties