#!/usr/bin/env bash 

set -ex

export ROOT_FOLDER=${PWD}

export BOSH_CONFIG=$PWD/bosh-director-config/bosh_config.yml

if [ "${STEMCELL_TYPE}" == "centos" ]
then
    # If we are on a centos deployment, deloyment name and release name will be suffixed
    DEPLOYMENT_NAME="${DEPLOYMENT_NAME}-centos"
    RELEASE_NAME="${RELEASE_NAME}-centos"
fi

bosh -e ${ALIAS} -n -d ${DEPLOYMENT_NAME} \
		delete-deployment

# remove release
bosh -e ${ALIAS} -n delete-release ${RELEASE_NAME}

# removing orphaned disks

bosh -e ${ALIAS} disks --orphaned --column "Disk CID" --column "Deployment" \
	| cat \
	| awk -v dn=${DEPLOYMENT_NAME} '{
										if($2==dn)
											{
												printf "%s\n",$1
											}
										}' \
	| xargs -i -t bosh -e ${ALIAS} -n -d ${DEPLOYMENT_NAME} delete-disk {}

mkdir -p removed

pushd removed || exit 666
touch keyval.properties
popd