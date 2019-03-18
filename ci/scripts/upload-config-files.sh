#!/usr/bin/env sh 

set -e

apk add --update jq

ROOT_FOLDER=${PWD}

mkdir -p ~/.aws

# create cert file needed for aws
cat > ~/.aws/credentials <<EOF
[default]
aws_access_key_id=$ACCESS_KEY_ID
aws_secret_access_key=$SECRET_ACCESS_KEY
EOF

version=$(cat ${ROOT_FOLDER}/mongodb-new-version/metadata | jq -r '.version.ref')

aws_opt="--endpoint-url ${ENDPOINT_URL}"

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

cd to-upload || exit 666
#upload blob list
aws ${aws_opt} s3 cp config/blobs.yml s3://${BUCKET}/ci/blobs-${version}.yml
#upload final.yml
aws ${aws_opt} s3 cp config/final.yml s3://${BUCKET}/ci/final-${version}.yml
#upload private.yml
aws ${aws_opt} s3 cp config/private.yml s3://${BUCKET}/ci/private-${version}.yml
