#!/usr/bin/env sh 

set -e

apt update -y && apt install -y jq

ROOT_FOLDER=${PWD}

mkdir -p ${ROOT_FOLDER}/to-upload

cp -rp ${ROOT_FOLDER}/mongodb-bosh-release-patched/. ${ROOT_FOLDER}/to-upload

cd ${ROOT_FOLDER}/to-upload

# Removing previous mongodb references from blob.yml
sed -i "/^mongodb\/mongodb-.*-x86_64.*/,/sha:.*/d" ${ROOT_FOLDER}/to-upload/config/blobs.yml

version=$(cat ${ROOT_FOLDER}/mongodb-new-version/metadata | jq -r '.version.ref')
blob_file=$(cat ${ROOT_FOLDER}/mongodb-new-version/metadata | jq -r '.metadata[].value|split("/")[-1]|sub(".tgz$";".tar.gz")')

bosh add-blob ${ROOT_FOLDER}/mongodb-new-version/${blob_file} mongodb/${blob_file}

bosh upload-blobs

# copying config files including version in their names

ls config/* | xargs -i sh -c 'cp -rp "$1" $(echo "$1"|sed -e "s#\(^[^\.]*\)\(.*$\)#\1-'${version}'\2#")' {} {}
