#!/bin/bash

source `dirname $(readlink -f $0)`/setenv

if [ ${property_require_ssl} == 0 ]
then
	export MONGO_CMD="${JOBS_COMMON_DIR}/bin/mongo.sh"
else	
	export MONGO_CMD="${JOBS_COMMON_DIR}/bin/mongo-ssl.sh"
fi

mongo_DbTypeport = ${property_mongod_listen_port}

export DB=$1
shift
export PARAM="$@"

pushd /var/vcap/packages/mongodb/bin >/dev/null
if [ "${property_node_role}" == "sa" ]
then
	${MONGO_CMD} mongodb://${deployment_rs_config}/${DB} \
 	-u ${property_root_username} %> -p ${property_root_password} %> --authenticationDatabase admin ${PARAM}
else 	
	${MONGO_CMD} mongodb://${deployment_rs_config}/${DB}?replicaSet=<%= p("replication.replica_set_name") %> \
 	-u ${property_root_username} %> -p ${property_root_password} %> --authenticationDatabase admin ${PARAM}
fi

popd >/dev/null
exit 0
