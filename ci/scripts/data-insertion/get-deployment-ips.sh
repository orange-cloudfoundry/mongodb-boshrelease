#!/usr/bin/env bash 

set -e

export ROOT_FOLDER=${PWD}

export BOSH_CONFIG=$PWD/bosh-director-config/bosh_config.yml

pushd output || exit 666

[ -d ${ROOT_FOLDER}/deployment-specs ] && cp -rp ${ROOT_FOLDER}/deployment-specs/* .

bosh -e ${ALIAS} -d ${DEPLOYMENT_NAME} vms --column Ips | sed -e 's/[[:space:]]*$/,/g' \
			|tr -d "\n" \
			|sed -e 's/,$//' -e 's/^/ips=\"/' -e 's/$/\"/' \
			>> keyval.properties

popd