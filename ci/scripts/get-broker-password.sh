#!/usr/bin/env sh 

set -e

ROOT_FOLDER=${PWD}

credhub api ${IP}:${PORT} --skip-tls-validation
( echo ${USER} ; echo ${PASSWORD} ) \
    | credhub login

mkdir -p broker-password
cd broker-password || exit 666

credhub g -n /${BOSH_ALIAS}/${DEPLOYMENT_NAME}/broker_password -j \
	| jq -r '.value' \
	> password.txt