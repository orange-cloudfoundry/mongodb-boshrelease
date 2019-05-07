#!/usr/bin/env sh 

set -e

ROOT_FOLDER=${PWD}


mkdir -p output || exit 666
cd output 
cat ${ROOT_FOLDER}/keyval.properties|grep -w "^deployed_version"| cut -d"=" -f2 > version
cd -

exit 0