#!/usr/bin/env sh

set -ex

export BOSH_CONFIG=$PWD/bosh-director-config/bosh_config.yml

ROOT_FOLDER=${PWD}

cat ${ROOT_FOLDER}/deployment-specs/keyval.properties \
  | grep -v -E "^UPDATED|^UUID" \
  > ${ROOT_FOLDER}/deployment-specs/sourced.properties

source ${ROOT_FOLDER}/deployment-specs/sourced.properties


shield api --ca-cert "${SHIELD_CA}" ${SHIELD_CORE} shield-tests

export SHIELD_CORE=shield-tests

shield login

if [ "${STEMCELL_TYPE}" == "centos" ]
then
    # If we are on a centos deployment, deloyment name will be suffixed
    SHIELD_TARGET="${SHIELD_TARGET}-centos"
fi

# removing previous archives

for target_name in $(shield targets --json \
	| jq -r '.[].name' \
	| sed -e '/^'${SHIELD_TARGET}'-[0-9.]*$/!d')
do
	# retrieving targets UUID
	target_uuid=$(shield target ${target_name} --json | jq -r '.uuid') 

	for i in $(shield archives --target ${target_uuid} --json \
			|jq -r '.[]|select(.status|inside("valid"))|select(.status|contains("valid"))|.uuid')
	do
		shield purge-archive $i --yes
	done
done


backup_ok=false

for ip in $(echo ${ips}|tr -s ',' ' ') 
do
	if ! ${backup_ok} ; then
		shield run-job "${ip}-backup-test" --yes
		[ $? -eq 0 ] && backup_ok=true 
	fi
done


# wait for a valid 


# check the logs of the the backup for dedicated db/collection archiving 
# on the firsts attempts the backup is not well realized 

task_uuid=""
for target_name in $(shield targets --json \
        | jq -r '.[].name' \
        | sed -e "/^${SHIELD_TARGET}-[0-9.]*$/!d")
do
    if [ "$task_uuid" == "" ]
    then

        # retrieving targets UUID
        target_uuid=$(shield target ${target_name} --json | jq -r '.uuid')
        for i in $(shield tasks --target ${target_uuid} --json |jq -r '.[].uuid')
        do
        	if [ "$task_uuid" == "" ]
			then
                while [ "$(shield task $i --json |jq -r '.status')" == "pending" ]
                do
                	sleep 5
                done
                archive_uuid=$(shield task $i --json |jq -r '.archive_uuid')
                archive_status=$(shield archive $archive_uuid --json | jq -r '.status')
                [ "$archive_status" == "valid" ] && task_uuid=$i
            fi
        done
    fi
done
task_status=$(shield task $task_uuid --json \
			|jq -r '.|select(.log|contains("done dumping '${DB}'.'${COLLECTION}'"))|true')
if [ "$task_status" != "true" ]
then
        exit 1
fi

