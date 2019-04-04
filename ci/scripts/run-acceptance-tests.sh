#!/usr/bin/env bash

set -ex

export BOSH_CONFIG=$PWD/bosh-director-config/bosh_config.yml

ROOT_FOLDER=${PWD}

bosh -e ${ALIAS} -d ${DEPLOYMENT_NAME} run-errand acceptance-tests
