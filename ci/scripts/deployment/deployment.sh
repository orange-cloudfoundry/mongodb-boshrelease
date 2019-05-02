#!/usr/bin/env bash 

set -e

apt-get install -qqy jq

export ROOT_FOLDER=${PWD}

export BOSH_CONFIG=$PWD/bosh-director-config/bosh_config.yml

deployment_var_init="   -v deployment_name=${DEPLOYMENT_NAME} \
                        -v release_name=${RELEASE_NAME} \
                        -v deployments-network=${DEPLOYMENT_NETWORK} \
                        -v mongo-port=${MONGO_PORT} \
                        -v persistent_disk_type=${PERSISTENT_DISK_TYPE} \
                        -v vm_type=${VM_TYPE} \
                        -v root_username=${ROOT_USERNAME} \
                        -v nb_instances=${NB_INSTANCES}"


if [ "${CURRENT}" == "true" ]
then
   MONGODB_VERSION=`cat ${ROOT_FOLDER}/mongodb-version/version`
else
   MONGODB_VERSION=`cat ${ROOT_FOLDER}/mongodb-new-version/metadata|jq -r '.version.ref'`
fi


if [ "${SHARDED}" == "true" ]
then
    # sharding is not implemented for 3.4 version of mongodb release
    # if version si not >= 3.6.X then deploy new version instead of prod version

    if [ $(echo ${MONGODB_VERSION} | cut -d"." -f1) -le 3 -a $(echo ${MONGODB_VERSION} | cut -d"." -f2) -lt 6 ]
    then
        MONGODB_VERSION=`cat ${ROOT_FOLDER}/mongodb-new-version/metadata|jq -r '.version.ref'`
    fi

    MANIFEST=manifest-shard.yml
    operations_dir="sharding"
    catalog_label="Sharded Cluster - Continuous Interation Tests"
else
    MANIFEST=manifest-rs.yml
    operations_dir="replicaset"
    catalog_label="Single Replicaset - Continuous Interation Tests"
fi

deployment_ops_files_cmd=""
for i in ${OPSFILES}
do
  if [ -f ${ROOT_FOLDER}/mongodb-bosh-release-patched/operations/$i ]
  then
    deployment_ops_files_cmd="${deployment_ops_files_cmd} -o ${ROOT_FOLDER}/mongodb-bosh-release-patched/operations/$i"
  fi
  if [ -f ${ROOT_FOLDER}/mongodb-bosh-release-patched/operations/${operations_dir}/$i ]
  then
    deployment_ops_files_cmd="${deployment_ops_files_cmd} -o ${ROOT_FOLDER}/mongodb-bosh-release-patched/operations/${operations_dir}/$i"
  fi
done  

# if using acceptance-tests opsfile using the same vm flavour
if [[ ${OPSFILES} == *"enable-mongodb-acceptance-test.yml"* ]]
then
    deployment_var_init="${deployment_var_init} \
                        -v accept_vm_type=${VM_TYPE}"
fi

# if using broker opsfiles, setting the appropriate variables
if [[ ${OPSFILES} == *"enable-mongodb-broker.yml"* ]]
then
   echo -n "broker_vm_type: ${BROKER_VM_TYPE}
broker_persistent_disk_type: ${BROKER_PERSISTENT_DISK_TYPE}
broker_catalog_yml: |
" > /tmp/broker_deployment_vars.yml
    # formatting catalog
    echo "${BROKER_CATALOG_YML}" > /tmp/broker_deployment_catalog.yml
    

    # generate dynamic opsfiles
    echo "---
- path: /services/id=mongodb-service-broker-ci/description
  type: replace
  value: MongoDB ${MONGODB_VERSION} Continous Integration tests" > /tmp/broker_description_ops.yml

    echo "---
- path: /services/id=mongodb-service-broker-ci/metadata/displayName
  type: replace
  value: MongoDB ${MONGODB_VERSION} ${catalog_label}" > /tmp/broker_displayname_ops.yml

    bosh interpolate /tmp/broker_deployment_catalog.yml -o /tmp/broker_description_ops.yml \
                                                     -o /tmp/broker_displayname_ops.yml \
                                                     > /tmp/broker_deployment_catalog.yml_

    mv /tmp/broker_deployment_catalog.yml_ /tmp/broker_deployment_catalog.yml                                                      

    sed -i -e "s/^/           /g" /tmp/broker_deployment_catalog.yml

    cat /tmp/broker_deployment_catalog.yml >> /tmp/broker_deployment_vars.yml                                                     

    # cat /tmp/broker_deployment_vars_yml >> /tmp/broker_deployment_vars
    deployment_var_init="${deployment_var_init} \
                        -l /tmp/broker_deployment_vars.yml"

    # if using broker route registrar opsfiles, setting cloudfoundry variables

    deployment_var_init="${deployment_var_init} \
                        -v cf.nats_host=${CF_NATS_HOST} \
                        -v cf.nats_password=${CF_NATS_PASSWORD} \
                        -v cf.system_domain=${CF_SYSTEM_DOMAIN}"

    # If we are in sharding mode, then use-broker-shard-links.yml MUST be used
    if [ "${SHARDED}" == "true" ]
    then
      deployment_ops_files_cmd="${deployment_ops_files_cmd} -o ${ROOT_FOLDER}/mongodb-bosh-release-patched/operations/${operations_dir}/use-broker-shard-links.yml"
    fi

fi   

# if using broker smoke-tests opsfiles, setting appropriate cloudfoundry variables
if [[ ${OPSFILES} == *"enable-mongodb-broker-smoke-tests.yml"* ]]
then
    deployment_var_init="${deployment_var_init} \
                        -v cf.api.url=https://api.${CF_SYSTEM_DOMAIN} \
                        -v cf.admin.password=${CF_ADMIN_PASSWORD} \
                        -v cf.org=${CF_ORG} \
                        -v cf.space=${CF_SPACE} \
                        -v cf.mongodb.appdomain=${CF_SYSTEM_DOMAIN}"
fi   


deployment_ops_files_cmd="${deployment_ops_files_cmd} \
-o ${ROOT_FOLDER}/mongodb-bosh-release-patched/operations/use-specific-mongodb-release.yml"


deployment_var_init="${deployment_var_init} \
                     -v mongodb-release-version=${MONGODB_VERSION}"


if [ "${REQUIRE_SSL}" == "true" ]
then
    deployment_var_init="${deployment_var_init} \
                    -v ca_name=${CA_NAME}"
fi    

bosh -e ${ALIAS} deploy -n -d ${DEPLOYMENT_NAME} \
        ${ROOT_FOLDER}/mongodb-bosh-release-patched/manifests/${MANIFEST} \
        ${deployment_ops_files_cmd} \
        ${deployment_var_init}

mkdir -p ${ROOT_FOLDER}/output
echo "deployed_version=${MONGODB_VERSION}">${ROOT_FOLDER}/output/keyval.properties

