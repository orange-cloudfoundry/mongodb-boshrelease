#!/usr/bin/env sh 

set -ex

ROOT_FOLDER=${PWD}

mkdir -p ~/.aws

# create cert file needed for aws
cat > ~/.aws/credentials <<EOF 
[default]
aws_access_key_id=${ACCESS_KEY_ID}
aws_secret_access_key=${SECRET_ACCESS_KEY}
EOF

cd mongodb-bosh-release-patched || exit 666

# Renamming
cat  blob_mv_list.lst | while read src dst
do
	if [ "$src" != "$dst" ]
	then
		echo renamming ${src} to ${dst}
		aws --endpoint-url ${ENDPOINT_URL} \
		--no-verify-ssl s3 mv s3://${BUCKET}/${src} s3://${BUCKET}/${dst} \
		2>/dev/null
		sed -i -e "s/${src}/${dst}/" config/blobs.yml
	fi
done

# exporting config files ()


# retrievieng config files
for i in $(ls config)
do
	aws --endpoint-url ${ENDPOINT_URL} --no-verify-ssl s3 cp config/$i s3://${BUCKET}/${CONFIG_PATH}/$i 2>/dev/null \

done

exit 0