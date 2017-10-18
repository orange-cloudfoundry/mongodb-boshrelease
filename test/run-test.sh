#!/usr/bin/env bash


SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P || exit 115)
RELEASE_DIR=$(cd "$SCRIPT_DIR/.." && pwd -P || exit 115)

BOLD=$(tput bold)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
BLUE=$(tput setaf 4)
NORMAL=$(tput sgr0)

function look_for_deviance() {
	local job=$1
	local template=$2
	local fixture_spec=$3
	local expected_result_file=$4

	echo -e "\nTesting template '$BOLD$BLUE$template$NORMAL' with fixture '$BOLD$BLUE$fixture_spec$NORMAL'."
	colordiff -u \
		"$SCRIPT_DIR/expected-results/$expected_result_file" \
		<("$SCRIPT_DIR/render.rb" \
			"$RELEASE_DIR/jobs/$job/templates/$template" \
			"$SCRIPT_DIR/fixtures/${fixture_spec}.yml")
	if [ "$?" -eq 0 ]; then
		echo "$BOLD${GREEN}OK$NORMAL"
	else
		echo "$BOLD${RED}KO$NORMAL"
	fi
}

fixtures=(standard-setup)
job=mongodb-server
for fixture in "${fixtures[@]}"; do
	template=config/mongod.conf.erb
	look_for_deviance $job $template $fixture mongod-${fixture}.conf

	template=js/create_admin_user.js.erb
	look_for_deviance $job $template $fixture create_admin_user-${fixture}.js

	template=js/initiate_rs.js.erb
	look_for_deviance $job $template $fixture initiate_rs-${fixture}.js
done

echo
