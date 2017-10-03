#!/usr/bin/env bash

# Setup env vars and folders for the ctl script
# This helps keep the ctl script as readable
# as possible

# Usage options:
# source /var/vcap/jobs/foobar/helpers/ctl_setup.sh JOB_NAME OUTPUT_LABEL
# source /var/vcap/jobs/foobar/helpers/ctl_setup.sh foobar
# source /var/vcap/jobs/foobar/helpers/ctl_setup.sh foobar foobar
# source /var/vcap/jobs/foobar/helpers/ctl_setup.sh foobar nginx

set -e # exit immediately if a simple command exits with a non-zero status
set -u # report the usage of uninitialized variables

JOB_NAME=$1
output_label=${2:-${JOB_NAME}}

export JOB_DIR=/var/vcap/jobs/$JOB_NAME
chmod 755 $JOB_DIR # to access file via symlink

# Load some bosh deployment properties into env vars
# Try to put all ERb into data/properties.sh.erb
# incl $NAME, $JOB_INDEX, $WEBAPP_DIR
source $JOB_DIR/data/properties.sh

source $JOB_DIR/helpers/ctl_utils.sh
redirect_output ${output_label}

export HOME=${HOME:-/home/vcap}

# Add all packages' /bin & /sbin into $PATH
for package_bin_dir in $(ls -d /var/vcap/packages/*/*bin)
do
  export PATH=${package_bin_dir}:$PATH
done

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-''} # default to empty
for package_lib_dir in $(ls -d /var/vcap/packages/*/lib /var/vcap/packages/*/lib64)
do
  export LD_LIBRARY_PATH=${package_lib_dir}:$LD_LIBRARY_PATH
done



# Setup log, run and tmp folders

export RUN_DIR=/var/vcap/sys/run/$JOB_NAME
export LOG_DIR=/var/vcap/sys/log/$JOB_NAME
export TMP_DIR=/var/vcap/sys/tmp/$JOB_NAME
export STORE_DIR=/var/vcap/store/$JOB_NAME
export DATA_DIR=$STORE_DIR/data
export TMPDIR=$TMP_DIR

PIDFILE=$RUN_DIR/$output_label.pid
