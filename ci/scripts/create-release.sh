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

bosh -e ${ALIAS} cr --force

bosh -e ${ALIAS} ur 