#!/usr/bin/env sh 

set -xe

ROOT_FOLDER=${PWD}

mkdir -p ${ROOT_FOLDER}/mongodb-bosh-release-patched

cp -rp ${ROOT_FOLDER}/mongodb-bosh-release/. ${ROOT_FOLDER}/mongodb-bosh-release-patched

if [ "${USE_RELEASE_CONFIG}" != "true" ]
then

	mkdir -p ~/.aws

	# create cert file needed for aws
	cat > ~/.aws/credentials <<-EOF 
	[default]
	aws_access_key_id=$ACCESS_KEY_ID
	aws_secret_access_key=$SECRET_ACCESS_KEY
	EOF

	if [ "${MONGODB_VERSION}" == "" -a "${CURRENT}" != "true" ]
	then
	  if [ -d ${ROOT_FOLDER}/mongodb-version ]
	  then	
	  	MONGODB_VERSION=`cat ${ROOT_FOLDER}/mongodb-version/version`
	  fi
	fi

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

	cd mongodb-bosh-release-patched || exit 666

	SUFFIX=""
	[ "$MONGODB_VERSION" != "" ] && $SUFFIX="-${MONGODB_VERSION}"

	#retrieve blob list
	aws ${aws_opt} s3 \
		cp s3://${BUCKET}/${CONFIG_PATH}/blobs${SUFFIX}.yml config/blobs.yml \
		||echo "no archived blobs.yml, use release default one"

	#retrieve final.yml
	aws ${aws_opt} s3 \
		cp s3://${BUCKET}/${CONFIG_PATH}/final${SUFFIX}.yml config/final.yml \
		||echo "no archived final.yml, use release default one"

	#retrieve private.yml
	aws ${aws_opt} s3 \
		cp s3://${BUCKET}/${CONFIG_PATH}/private${SUFFIX}.yml config/private.yml  \
		||echo "no archived private.yml, use release default one"

	#get the list of availables blobs ids on blobsore
	aws ${aws_opt} s3 ls s3://${BUCKET}/ > blobstore_ids.list

	# keeping only needed version of golang package
	if [ ! -z ${GOLANG_VERSION} ]
	then
		for d in $(find .final_builds/packages -type d \
									-name 'golang*' \
									! -name '*-'${GOLANG_VERSION}'-*')
		do
			[ -d ${d} ] && rm -rf ${d}
		done
		for d in $(find ./packages -type d \
					  -name 'golang*' \
					  ! -name '*-'${GOLANG_VERSION}'-*')
		do
			[ -d ${d} ] && rm -rf ${d}
		done
	fi
fi
