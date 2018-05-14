#!/bin/bash

set -e # exit immediately if a simple command exits with a non-zero status.
set -u # report the usage of uninitialized variables.

source ${JOB_DIR}/bin/setenv

source ${JOB_DIR}/bin/mdb-variables.sh


pushd `dirname $(readlink -f $0)` >/dev/null
cd ${MONGODB_SSL}

# generate only if client and server keys doesnt already exists
if [ ! -f ${MONGODB_SSL}/mongodb.pem ]
then
	# retrieving openssl.cnf - location is OS ependent
	OPENSSL_CNF=`find /etc -name 'openssl.cnf'`

    openssl genrsa -out ${MONGODB_SSL}/mongodb.key 2048
    
    openssl req -new -key ${MONGODB_SSL}/mongodb.key \
	    -out ${MONGODB_SSL}/mongodb.csr \
	    -reqexts SAN \
		-extensions SAN \
		-config <(cat ${OPENSSL_CNF} \
          <(printf "[SAN]\nsubjectAltName=IP.1:"${deployment_current_ip}",IP.2:127.0.0.1\nextendedKeyUsage=serverAuth,clientAuth")) \
	    -subj "/C=FR/ST=Paris/L=Paris/O=Orange/OU=CloudFoundry/CN="${deployment_current_ip}
	    
    openssl x509 -req -in ${MONGODB_SSL}/mongodb.csr \
	    -CA ${MONGODB_SSL}/CA.crt \
	    -CAkey ${MONGODB_SSL}/CA.key \
	    -CAcreateserial -out ${MONGODB_SSL}/mongodb.crt \
	    -days 3650 -sha256

    cat ${MONGODB_SSL}/mongodb.key \
    	${MONGODB_SSL}/mongodb.crt > ${MONGODB_SSL}/mongodb.pem
fi

popd >/dev/null
exit 0