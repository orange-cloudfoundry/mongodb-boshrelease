#!/bin/bash

export JOBS_COMMON_DIR=/var/vcap/packages/mongodb-jobs-common
export JOB_NAME=$1

source ${JOBS_COMMON_DIR}/bin/setenv ${JOB_NAME}

source ${JOB_DIR}/bin/mdb-variables.sh

if [ ${property_require_ssl} == 0 ]
then
	export MONGO_CMD="${JOBS_COMMON_DIR}/bin/mongo.sh"
else	
	export MONGO_CMD="${JOBS_COMMON_DIR}/bin/mongo-ssl.sh"
fi

export DB=$1
shift
export PARAM="$@"

pushd /var/vcap/packages/mongodb/bin >/dev/null
if [ "${property_node_role}" == "sa" ]
then
	${MONGO_CMD} mongodb://${deployment_rs_config}/${DB} \
		-u ${property_root_username} \
		-p ${property_root_password} \
		--authenticationDatabase admin ${PARAM}
	else
	${MONGO_CMD} mongodb://${deployment_rs_config}/${DB}?replicaSet=${property_replica_set_name} \
		-u ${property_root_username} \
		-p ${property_root_password} \
		--authenticationDatabase admin ${PARAM}
fi

popd >/dev/null
exit 0