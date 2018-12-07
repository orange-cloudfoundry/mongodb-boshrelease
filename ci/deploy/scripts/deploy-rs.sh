#!/usr/bin/env bash 

set -ex

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


if [ "${STEMCELL_TYPE}" == "centos" ]
then
    # If we are on a centos deployment, deloyment name and release name will be suffixed
    DEPLOYMENT_NAME="${DEPLOYMENT_NAME}-centos"
    RELEASE_NAME="${RELEASE_NAME}-centos"
fi

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
deployment_var_init="   -v appli=${DEPLOYMENT_NAME} \
                        -v mongodb-release=${RELEASE_NAME} \
                        -v deployments-network=${DEPLOYMENT_NETWORK} \
                        -v shield-url=${SHIELD_URL} \
                        -v shield-token=${SHIELD_TOKEN} \
                        -v shield-tenant=${SHIELD_TENANT} \
                        -v shield-storage=${SHIELD_STORAGE} \
                        -v mongo-port=${MONGO_PORT} \
                        -v persistent-disk-type=${PERSISTENT_DISK_TYPE} \
                        -v vm-type=${VM_TYPE} \
                        -v root-username=${ROOT_USERNAME}"

deployment_ops_files_cmd=""

if [ "${STEMCELL}" != "" ]
then
    deployment_var_init="${deployment_var_init} \
                    -v stemcell-version=${STEMCELL} -v stemcell-alias=${STEMCELL_ALIAS} -v stemcell-os=${STEMCELL_OS}"
    deployment_ops_files_cmd="${deployment_ops_files_cmd} \
                    -o ${ROOT_FOLDER}/mongodb-compilation-bosh-release/ci/manifests/opsfiles/mongo-bootstrap-stemcell.yml"
fi

if [ "${STEMCELL_TYPE}" == "centos" ]
then
    deployment_ops_files_cmd="${deployment_ops_files_cmd} \
                    -o ${ROOT_FOLDER}/mongodb-compilation-bosh-release/ci/manifests/opsfiles/centos.yml"
fi

if [ "${ENGINE}" == "rocksdb" ]
then
    deployment_ops_files_cmd="${deployment_ops_files_cmd} \
                    -o ${ROOT_FOLDER}/mongodb-compilation-bosh-release/ci/manifests/opsfiles/rocksdb.yml"
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
        ${ROOT_FOLDER}/mongodb-compilation-bosh-release/ci/manifests/deployment-manifest.yml \
        ${deployment_ops_files_cmd}

popd