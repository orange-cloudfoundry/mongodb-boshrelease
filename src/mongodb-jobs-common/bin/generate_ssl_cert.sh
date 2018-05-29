#!/usr/bin/env bash

set -e # exit immediately if a simple command exits with a non-zero status.
set -u # report the usage of uninitialized variables.

source ${JOB_DIR}/bin/mdb-variables.sh

cd "${MONGODB_SSL}" || exit 666

# generate only if client and server keys doesnt already exists
if [ ! -f "${MONGODB_SSL}/mongodb.pem" ]
then
    # We need to reset LD Library path to use system deployed openssl version
    LD_LIBRARY_PATH=""

    # retrieving openssl.cnf - location is OS ependent
    OPENSSL_CNF=`find /etc -name 'openssl.cnf'`

    # generate private key
    openssl genrsa -out ${MONGODB_SSL}/mongodb.key 2048

  # We had to define both IP and DNS close because without DNS, mongo do not detect the sans and provide messages like:
        # 2018-05-30T16:13:25.548+0000 I NETWORK  [thread1] All nodes for set rs0 are down. This has happened for 6 checks in a row.
        # 2018-05-30T16:13:26.051+0000 E NETWORK  [thread1] The server certificate does not match the host name. Hostname: 10.165.0.75 does not match SAN(s): 
        # 2018-05-30T16:13:26.053+0000 E NETWORK  [thread1] The server certificate does not match the host name. Hostname: 10.165.0.74 does not match SAN(s): 
        # 2018-05-30T16:13:26.055+0000 E NETWORK  [thread1] The server certificate does not match the host name. Hostname: 10.165.0.73 does not match SAN(s): 
    # And ginkgo only support IPs SANs on its side...  
    SAN_SECTION="[SAN]\nsubjectAltName=IP.1:${deployment_current_ip},IP.2:127.0.0.1,DNS.1:${deployment_current_ip},DNS.2:127.0.0.1\nextendedKeyUsage=serverAuth,clientAuth\n"

    # generate certification request
    openssl req -new -key "${MONGODB_SSL}/mongodb.key" \
        -out "${MONGODB_SSL}/mongodb.csr" \
        -reqexts SAN \
        -config <(cat "${OPENSSL_CNF}" <(printf "${SAN_SECTION}")) \
        -subj "/C=FR/ST=Paris/L=Paris/O=Orange/OU=CloudFoundry/CN=${deployment_current_ip}"

    # sign certificate
    openssl x509 -req -in "${MONGODB_SSL}/mongodb.csr" \
        -extensions SAN \
        -extfile <(printf "${SAN_SECTION}") \
        -CA "${MONGODB_SSL}/CA.crt" \
        -CAkey "${MONGODB_SSL}/CA.key" \
        -CAcreateserial -out "${MONGODB_SSL}/mongodb.crt" \
        -days 3650 -sha256

    cat "${MONGODB_SSL}/mongodb.key" \
        "${MONGODB_SSL}/mongodb.crt" \
        > "${MONGODB_SSL}/mongodb.pem"

fi
