#!/usr/bin/env sh 

set -e

ROOT_FOLDER=${PWD}

echo "${CREDHUB_CA}" >/tmp/credhub_ca
echo "${UAA_CA}" >/tmp/uaa_ca

credhub api ${IP}:${PORT} --ca-cert /tmp/credhub_ca --ca-cert /tmp/uaa_ca
credhub login -u ${USER} -p ${PASSWORD}

credhub n -t password -n /${BOSH_ALIAS}/${DEPLOYMENT_NAME}/root_password
