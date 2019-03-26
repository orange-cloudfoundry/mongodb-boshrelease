#!/usr/bin/env sh 

set -e

export ROOT_FOLDER=${PWD}

mkdir -p keyvalout

pushd keyvalout || exit 666

if [ "${VALUE}" == "DATE" ]
then
  VALUE=$(date+%Y-%m-%d)
fi  

echo "${KEY}=${VALUE}" > keyval.properties

popd
