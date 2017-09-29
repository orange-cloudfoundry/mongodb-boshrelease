#!/usr/bin/env bash


SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P || exit 115)
RELEASE_DIR=$(cd "$SCRIPT_DIR/.." && pwd -P || exit 115)


profile=$1

if [ -z "$profile" ]; then
	echo "ERROR: missing argument: profile" >&2
	exit 2
fi

colordiff -u \
	"$SCRIPT_DIR/mongod-${profile}.conf" \
	<("$SCRIPT_DIR/render.rb" \
		"$RELEASE_DIR/jobs/mongodb-server/templates/config/mongod.conf.erb" \
		"$SCRIPT_DIR/${profile}.yml")
