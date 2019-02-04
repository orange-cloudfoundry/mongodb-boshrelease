#!/usr/bin/env sh 

set -ex

ROOT_FOLDER=${PWD}

echo "${CREDHUB_CA}" >/tmp/credhub_ca
echo "${UAA_CA}" >/tmp/uaa_ca

credhub api ${IP}:${PORT} --ca-cert /tmp/credhub_ca --ca-cert /tmp/uaa_ca
credhub login -u ${USER} -p ${PASSWORD}

mkdir -p broker-password
cd broker-password || exit 666

credhub g -n /${BOSH_ALIAS}/${DEPLOYMENT_NAME}/broker_password -j \
	| jq -r '.value' \
	> password.txt