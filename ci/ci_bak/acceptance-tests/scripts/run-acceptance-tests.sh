#!/usr/bin/env bash

set -ex

export BOSH_CONFIG=$PWD/bosh-director-config/bosh_config.yml

ROOT_FOLDER=${PWD}

if [ "${STEMCELL_TYPE}" == "centos" ]
then
    # If we are on a centos deployment, deloyment name will be suffixed
    DEPLOYMENT_NAME="${DEPLOYMENT_NAME}-centos"
fi

bosh -e ${ALIAS} -d ${DEPLOYMENT_NAME} run-errand acceptance-tests
