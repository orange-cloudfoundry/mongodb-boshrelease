#!/usr/bin/env bash 

set -e

export ROOT_FOLDER=${PWD}

export BOSH_CONFIG=$PWD/bosh-director-config/bosh_config.yml

bosh -e ${ALIAS} -d ${DEPLOYMENT_NAME} run-errand broker-smoke-tests