#!/usr/bin/env bash 

set -e

apt-get install -y jq

ROOT_FOLDER=${PWD}

export BOSH_CONFIG=$PWD/bosh-director-config/bosh_config.yml

pushd mongodb-bosh-release-patched|| exit 666

if [ "${CURRENT}" == "true" ]
then
  MONGODB_VERSION=`cat ${ROOT_FOLDER}/mongodb-version/version`
else
  MONGODB_VERSION=`cat ${ROOT_FOLDER}/mongodb-new-version/metadata|jq -r '.version.ref'`
fi

# Updating final.yml with release name specified in settings
sed -i -e "s/^\(final_name:\).*/\1 ${BOSH_RELEASE}/" config/final.yml

# removing all deployments linked to the release
bosh -e ${ALIAS} deployments --json \
	| jq -r '.Tables[].Rows[]|select(.release_s|contains("'${DEPLOYMENT_NAME}'/'${MONGODB_VERSION}'"))|.name' \
	| xargs -i bosh -e ${ALIAS} delete-deployment -n -d {} --force

# removing already existing release if exists
bosh -e ${ALIAS} releases | cat | grep ${MONGODB_VERSION} |while read rel ver other
do
	if [ "${rel}" == "${BOSH_RELEASE}" ]
	then	
		bosh -e ${ALIAS} -n delete-release ${rel}/${ver}
	fi
done
 
bosh -e ${ALIAS} create-release --force --version ${MONGODB_VERSION}

bosh -e ${ALIAS} upload-release

popd
