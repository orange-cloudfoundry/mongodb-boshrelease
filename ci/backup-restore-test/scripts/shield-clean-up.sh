#!/usr/bin/env sh

set -ex

ROOT_FOLDER=${PWD}

cat ${ROOT_FOLDER}/deployment-specs/keyval.properties \
  | grep -v -E "^UPDATED|^UUID" \
 > ${ROOT_FOLDER}/deployment-specs/sourced.properties

source ${ROOT_FOLDER}/deployment-specs/sourced.properties 

shield api --ca-cert "${SHIELD_CA}" ${SHIELD_CORE} shield-tests

export SHIELD_CORE=shield-tests

if [ "${STEMCELL_TYPE}" == "centos" ]
then
    # If we are on a centos deployment, deloyment name will be suffixed
    SHIELD_TARGET="${SHIELD_TARGET}-centos"
fi

shield login

for target_name in $(shield targets --json \
	| jq -r '.[].name' \
	| sed -e "/^${SHIELD_TARGET}-[0-9.]*$/!d")
do
	# retrieving targets UUID
	target_uuid=$(shield target ${target_name} --json | jq -r '.uuid') 

	for i in $(shield jobs --target ${target_uuid} --json |jq -r '.[].uuid')
	do
		shield delete-job $i --yes
	done

	shield delete-target ${target_uuid} --yes
	
done