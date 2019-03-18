#!/usr/bin/env bash 

set -e

apt update

#avoiding error 407 with cntlm proxy
RET=1
while [ $RET -ne 0 ]
do
  >/tmp/apt.log
  apt install -y jq python python-yaml | tee -a /tmp/apt.log
  RET=$(grep -w 407 /tmp/apt.log|grep "Proxy Authentication Required"|wc -l)
done

export ROOT_FOLDER=${PWD}

export BOSH_CONFIG=$PWD/bosh-director-config/bosh_config.yml

cp -rp mongodb-bosh-release/. mongodb-bosh-release-patched/

pushd mongodb-bosh-release || exit 666
# retrieving the blobs locally

bosh -e ${ALIAS} sync-blobs

# retrieving blob list in a json file

bosh blobs --json|jq  -r '.Tables[].Rows[]' > $ROOT_FOLDER/mongodb-bosh-release-patched/blob-list.json

popd 

pushd mongodb-bosh-release-patched

# removing old files
rm -f config/*.yml

# generating new final.yml
cat > config/final.yml <<-EOF
	---
	final_name: bidon
	blobstore:
	  provider: s3
	  options:
	    bucket_name: ${BUCKET}
	    host: ${ENDPOINT_URL}
	EOF

# feeding private.yml
cat > config/private.yml <<-EOF
	---
	blobstore:
	  options:
	    access_key_id: '${ACCESS_KEY_ID}'
	    secret_access_key: '${SECRET_ACCESS_KEY}'
	    ssl_verify_peer: false
	EOF
if [ ${SIGNATURE_VERSION} -ne 4 ]
then
	echo "    signature_version: '${SIGNATURE_VERSION}'" >> config/private.yml
fi

# create empty blobs.yml
touch config/blobs.yml

# adding the blobs to the ci blobstore

for i in $(cat blob-list.json | jq -r '.path')
do
	bosh add-blob ${ROOT_FOLDER}/mongodb-bosh-release/blobs/$i $i
done

bosh upload-blobs

bosh blobs --json|jq  -r '.Tables[].Rows[]' > current-blob-list.json

# create blobs matching file
cat current-blob-list.json |jq  -r '[.path,.blobstore_id]|@tsv'|while read blob id
do
	dest_id=$(cat blob-list.json |jq  -r 'select(.path|contains("'${blob}'"))|.blobstore_id')
	echo "$id $dest_id" >> blob_mv_list.lst
done

# the go vendor package case ...

# which version of golang is used on git ?
go_git_fingerprint=$(cat packages/golang-${GOLANG_VERSION}-linux/spec.lock \
					| sed -e s/:[[:space:]]*/:/g 			 \
					| grep fingerprint 						 \
					| cut -d":" -f2 )

git clone https://github.com/bosh-packages/golang-release ${ROOT_FOLDER}/golang-release

cd ${ROOT_FOLDER}/golang-release

fingerprint_tag="$(grep -l -r -F ${go_git_fingerprint} releases/ \
					| sort \
					|tail -1 \
					| sed -e 's/^.*\([[0-9]]*\.[[0-9]]*\.[[0-9]]*\).*$/v\1/')"

git checkout ${fingerprint_tag}

cd -

dest_id=$(python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' < \
	${ROOT_FOLDER}/mongodb-bosh-release/.final_builds/packages/golang-${GOLANG_VERSION}-linux/index.yml \
	| jq -r '.builds|map(select(.version|contains("'${go_git_fingerprint}'")))[0].blobstore_id')

[ -n "$(find .final_builds/packages -type d -name 'golang*')" ] && rm -rf .final_builds/packages/golang*
[ -n "$(find packages -type d -name 'golang*')" ] && rm -rf packages/golang*  

# reuploading golang

bosh vendor-package golang-${GOLANG_VERSION}-linux ${ROOT_FOLDER}/golang-release

# and now the id is ....
id=$(python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' < \
	.final_builds/packages/golang-${GOLANG_VERSION}-linux/index.yml \
	| jq -r '.builds|map(select(.version|contains("'${go_git_fingerprint}'")))[0].blobstore_id')

# appending to the list
echo "$id $dest_id" >> blob_mv_list.lst

popd