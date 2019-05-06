#!/usr/bin/env bash 

set -e

export ROOT_FOLDER=${PWD}

export BOSH_CONFIG=$PWD/bosh-director-config/bosh_config.yml

bosh -e ${ALIAS} -n -d ${DEPLOYMENT_NAME} \
		delete-deployment

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
