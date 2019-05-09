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

if [ "${MONGODB_VERSION}" == "" ]
then
  MONGODB_VERSION=`grep "^mongodb" ${ROOT_FOLDER}/versions/keyval.properties|cut -d"=" -f2`
fi

aws_opt="--endpoint-url ${ENDPOINT_URL}"
aws_compil_opt="--profile compil --endpoint-url ${COMPIL_ENDPOINT_URL}"

if ${SKIP_SSL}
then
  aws_opt="${aws_opt} --no-verify-ssl"
else 
  if [ "${SSL_CERT}" == "" ]
  then
    echo "You Have to provide an ssl certificate"
    exit 666
  else 
    cat > /tmp/ca-bundle.crt <<-EOF
	${SSL_CERT}
	EOF
	aws_opt="${aws_opt} --ca-bundle /tmp/ca-bundle.crt"
  fi  
fi

if ${COMPIL_SKIP_SSL}
then
  aws_compil_opt="${aws_compil_opt} --no-verify-ssl"
else 
  if [ "${COMPIL_SSL_CERT}" == "" ]
  then
    echo "You Have to provide an ssl certificate"
    exit 666
  else 
    cat > /tmp/compil-ca-bundle.crt <<-EOF
	${COMPIL_SSL_CERT}
	EOF
	aws_compil_opt="${aws_compil_opt} --ca-bundle /tmp/compil-ca-bundle.crt"
  fi  
fi

mkdir -p ${ROOT_FOLDER}/to-upload

cp -rp ${ROOT_FOLDER}/mongodb-bosh-release/. ${ROOT_FOLDER}/to-upload

cd to-upload || exit 666

#retrieve blob list
aws ${aws_opt} s3 \
	cp s3://${BUCKET}/ci/blobs.yml config/blobs.yml \
	||echo "no archived blobs.yml, use release default one"

#retrieve final.yml
aws ${aws_opt} s3 \
	cp s3://${BUCKET}/ci/final.yml config/final.yml \
	||echo "no archived final.yml, use release default one"

#retrieve private.yml
aws ${aws_opt} s3 \
	cp s3://${BUCKET}/ci/private.yml config/private.yml \
	||echo "no archived private.yml, use release default one"


# Removing previous mongodb references from blob.yml
sed -i "/^mongodb\/mongodb-.*-x86_64.*/,/sha:.*/d" ${ROOT_FOLDER}/to-upload/config/blobs.yml

for dist in ubuntu
do

  # Retrieving last compiled blob informations
  blob_info=$(sed -e "/^mongodb\/mongodb-${dist}-x86_64.*/,/sha:.*/!d" \
              ${ROOT_FOLDER}/mongodb-compilation-bosh-release-patched/config/blobs.yml)
  blobstore_id=$(echo "${blob_info}" |grep "object_id:"|tr -d [:space:] | cut -d":" -f2)

  # Adding compiled blob to release blobstore

  aws ${aws_compil_opt} s3 \
    cp s3://${COMPIL_BUCKET}/${blobstore_id} /tmp
  aws ${aws_opt} s3 \
    cp /tmp/${blobstore_id} s3://${BUCKET}/

  # Adding last uploaded blob to blobs.yml 
  echo "${blob_info}" \
    >> ${ROOT_FOLDER}/to-upload/config/blobs.yml

done