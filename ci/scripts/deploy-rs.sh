#!/usr/bin/env bash 

set -e

export ROOT_FOLDER=${PWD}

create_fake_files()
{
    # Creating fake files for already deployed releases

    if [ ! -d dev_releases/${RELEASE_NAME} ]
    then
        mkdir -p dev_releases/${RELEASE_NAME}
    fi

    bosh -e ${ALIAS} releases \
            | cat \
            | awk -v rn=${RELEASE_NAME} '{
                                            if ($1==rn)
                                                {
                                                    gsub("\*","");
                                                    printf "%s",$2;
                                                    gsub("\+","");
                                                    printf " %s\n",$3
                                                }
                                        }' \
            | while read version commit_hash                            
              do
     
                if [ ! -f dev_releases/${RELEASE_NAME}/index.yml ]
                then
                    echo "builds:" > dev_releases/${RELEASE_NAME}/index.yml
                fi
                if [ ! -f dev_releases/${RELEASE_NAME}/${RELEASE_NAME}-${version}.yml ]
                then
		            cat > dev_releases/${RELEASE_NAME}/${RELEASE_NAME}-${version}.yml <<-EOF
							name: ${DEPLOYMENT_NAME}
							version: ${version}
							commit_hash: ${commit_hash}
							uncommitted_changes: false
							EOF
		            cat >> dev_releases/${RELEASE_NAME}/index.yml <<-EOF
							  $(cat /proc/sys/kernel/random/uuid):
							    version: ${version}
							EOF
		        fi
    		done    
}

export BOSH_CONFIG=$PWD/bosh-director-config/bosh_config.yml

pushd mongodb-bosh-release-patched || exit 666

create_fake_files

# renaming final_name in final.yml

sed -i -e "s/\(^final_name: \).*$/\1 ${RELEASE_NAME}/" config/final.yml

# avoid checking jobs fingerprints
for i in $(find .final_builds -type d ! -path '*/packages' \
                           ! -path '*/packages/golang*' \
                           ! -path '.final_builds' \
                           -print )
do
        [ -d $i ] && rm -rf $i
done
deployment_var_init="   -v deployment_name=${DEPLOYMENT_NAME} \
                        -v release_name=${RELEASE_NAME} \
                        -v deployments-network=${DEPLOYMENT_NETWORK} \
                        -v mongo-port=${MONGO_PORT} \
                        -v persistent_disk_type=${PERSISTENT_DISK_TYPE} \
                        -v vm_type=${VM_TYPE} \
                        -v root-username=${ROOT_USERNAME} \
                        -v nb_instances=${NB_INSTANCES}"


deployment_ops_files_cmd=""
for i in ${OPSFILES}
do
  deployment_ops_files_cmd="${deployment_ops_files_cmd} -o ${ROOT_FOLDER}/mongodb-bosh-release-patched/operations/$i"
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
                    -o ${ROOT_FOLDER}/mongodb-bosh-release-patched/operations/use-rocksdb.yml"
fi

if [ "${REQUIRE_SSL}" == "true" ]
then
    deployment_var_init="${deployment_var_init} \
                    -v ca_name=${CA_NAME}"
fi    

bosh -e ${ALIAS} cr --force

bosh -e ${ALIAS} ur 

bosh -e ${ALIAS} deploy -n -d ${DEPLOYMENT_NAME} \
        ${deployment_var_init} \
        ${ROOT_FOLDER}/mongodb-bosh-release-patched/manifests/${MANIFEST} \
        ${deployment_ops_files_cmd}

popd