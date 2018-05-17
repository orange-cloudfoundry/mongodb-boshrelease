#!/bin/bash

export JOBS_COMMON_DIR=/var/vcap/packages/mongodb-jobs-common
export JOB_NAME=$1

shift

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
if [ "${JOB_NAME}" != "mongos" ]
then
# for mongos cfgsvr and shardsvr
	if [ "${property_node_role}" == "sa" ]
	then
	# only in mongod case
		connect_string="mongodb://${deployment_rs_config}/${DB}"
	else
		connect_string="mongodb://${deployment_rs_config}/${DB}?replicaSet=${property_replica_set_name}"
	fi
else
# mongos case
# before 3.6 mongos could only connect to spcefic address and do not accept addresses list
	current_version=$($MONGO_CMD --nodb --version \
					| perl -e '@in=<STDIN>;
								foreach $ln (@in){
									if ($ln=~/MongoDB shell version v(\d+.\d+.\d+).*/){
										print $1
									}
								}')
	major_version=$(echo ${current_version}|perl -e 'print((split(/\./,<STDIN>))[0])')
	mid_version=$(echo ${current_version}|perl -e 'print((split(/\./,<STDIN>))[1])')

	if [ ${major_version} -lt 3 -o ${mid_version} -lt 6 ]
	then
		connect_string="mongodb://${deployment_current_ip}:${property_mongod_listen_port}/${DB}"


	else
		connect_string="mongodb://${deployment_mongos_config}/${DB}"
	fi
fi

${MONGO_CMD} ${connect_string} \
	-u ${property_root_username} \
	-p ${property_root_password} \
	--authenticationDatabase admin ${PARAM}

popd >/dev/null
exit 0