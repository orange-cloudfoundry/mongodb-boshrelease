set -ex

export ROOT_FOLDER=${PWD}

export BOSH_CONFIG=$PWD/bosh-director-config/bosh_config.yml

# remove release
bosh -e ${ALIAS} -n delete-release ${RELEASE_NAME}