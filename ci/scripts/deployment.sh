#!/usr/bin/env bash 

set -ex

export ROOT_FOLDER=${PWD}

deployment_var_init="   -v deployment_name=${DEPLOYMENT_NAME} \
                        -v release_name=${RELEASE_NAME} \
                        -v deployments-network=${DEPLOYMENT_NETWORK} \
                        -v mongo-port=${MONGO_PORT} \
                        -v persistent_disk_type=${PERSISTENT_DISK_TYPE} \
                        -v vm_type=${VM_TYPE} \
                        -v root_username=${ROOT_USERNAME} \
                        -v nb_instances=${NB_INSTANCES}"


deployment_ops_files_cmd=""
for i in ${OPSFILES}
do
  deployment_ops_files_cmd="${deployment_ops_files_cmd} -o ${ROOT_FOLDER}/mongodb-bosh-release/operations/$i"
done  

# if using broker opsfiles, setting the appropriate variables
if [[ ${OPSFILES} == *"enable-mongodb-broker.yml"* ]]
then
   echo -n "broker_vm_type: ${BROKER_VM_TYPE}
broker_persistent_disk_type: ${BROKER_PERSISTENT_DISK_TYPE}
broker_catalog_yml: |
" > /tmp/broker_deployment_vars
    # formatting catalog
    echo "${BROKER_CATALOG_YML}" > /tmp/broker_deployment_vars_yml
    sed -i -e "s/^/  /g" /tmp/broker_deployment_vars_yml
    cat /tmp/broker_deployment_vars_yml >> /tmp/broker_deployment_vars
    deployment_var_init="${deployment_var_init} \
                        -l /tmp/broker_deployment_vars"
fi                        

# if using broker route registrar opsfiles, setting cloudfoundry variables
if [[ ${OPSFILES} == *"enable-mongodb-broker.yml"* ]]
then
    deployment_var_init="${deployment_var_init} \
                        -v cf.nats_host=${CF_NATS_HOST} \
                        -v cf.nats_password=${CF_NATS_PASSWORD} \
                        -v cf.system_domain=${CF_SYSTEM_DOMAIN}"
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


if [ "${ENGINE}" == "rocksdb" ]
then
    deployment_ops_files_cmd="${deployment_ops_files_cmd} \
                    -o ${ROOT_FOLDER}/mongodb-bosh-release/operations/use-rocksdb.yml"
fi

if [ "${REQUIRE_SSL}" == "true" ]
then
    deployment_var_init="${deployment_var_init} \
                    -v ca_name=${CA_NAME}"
fi    

bosh -e ${ALIAS} deploy -n -d ${DEPLOYMENT_NAME} \
        ${ROOT_FOLDER}/mongodb-bosh-release/manifests/${MANIFEST} \
        ${deployment_ops_files_cmd} \
        ${deployment_var_init} 

popd