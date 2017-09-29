#!/usr/bin/env bash

profile=$1

if [ -z "$profile" ]; then
	echo "ERROR: missing argument: profile" >&2
	exit 2
fi

colordiff -u \
	mongod-${profile}.conf \
	<(./render.rb config/mongod.conf.erb ${profile}.yml)
