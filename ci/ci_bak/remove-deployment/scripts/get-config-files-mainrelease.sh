#!/usr/bin/env sh 

set -ex

ROOT_FOLDER=${PWD}

mkdir -p ~/.aws

# create cert file needed for aws
cat > ~/.aws/credentials <<EOF 
[default]
aws_access_key_id=${ACCESS_KEY_ID}
aws_secret_access_key=${SECRET_ACCESS_KEY}
[compil]
aws_access_key_id=${COMPIL_ACCESS_KEY_ID}
aws_secret_access_key=${COMPIL_SECRET_ACCESS_KEY}
EOF

mkdir -p ${ROOT_FOLDER}/mongodb-bosh-release-patched

cp -rp ${ROOT_FOLDER}/mongodb-bosh-release/. ${ROOT_FOLDER}/mongodb-bosh-release-patched

cd mongodb-bosh-release-patched || exit 666

#retrieve blob list
aws --endpoint-url ${ENDPOINT_URL} --no-verify-ssl s3 cp s3://${BUCKET}/ci/blobs.yml config/blobs.yml 2>/dev/null \
||echo "no archived blobs.yml, use release default one"

#retrieve final.yml
aws --endpoint-url ${ENDPOINT_URL} --no-verify-ssl s3 cp s3://${BUCKET}/ci/final.yml config/final.yml 2>/dev/null \
||echo "no archived final.yml, use release default one"

#retrieve private.yml
aws --endpoint-url ${ENDPOINT_URL} --no-verify-ssl s3 cp s3://${BUCKET}/ci/private.yml config/private.yml 2>/dev/null \
||echo "no archived private.yml, use release default one"



# Retrieving last compiled blob informations
first_line=$(grep -nw "mongodb/mongodb-linux-x86_64-3.4.6.tar.gz" \
             ${ROOT_FOLDER}/mongodb-compilation-bosh-release-patched/config/blobs.yml \
            | cut -d":" -f1)
last_line=$((${first_line}+3))

blob_info=$(sed -n "${first_line},${last_line}p" ${ROOT_FOLDER}/mongodb-compilation-bosh-release-patched/config/blobs.yml)

blobstore_id=$(echo "${blob_info}" |grep "object_id:"|tr -d [:space:] | cut -d":" -f2)

# Adding compiled blob to release blobstore

aws --profile compil --endpoint-url ${COMPIL_ENDPOINT_URL} --no-verify-ssl s3 cp s3://${COMPIL_BUCKET}/${blobstore_id} /tmp 2>/dev/null
aws --endpoint-url ${ENDPOINT_URL} --no-verify-ssl s3 cp /tmp/${blobstore_id} s3://${BUCKET}/ 2>/dev/null

# Adding last uploaded blob to blobs.yml 
echo "${blob_info}">> ${ROOT_FOLDER}/mongodb-bosh-release-patched/config/blobs.yml

#get the list of availables blobs ids on blobstore
aws --endpoint-url ${ENDPOINT_URL} --no-verify-ssl s3 ls s3://${BUCKET}/ 2>/dev/null > blobstore_ids.list
