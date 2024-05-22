#!/usr/bin/env bash

##
# Implements hook -s 'cwt' -a 'alias' -v 'PROVISION_USING'.
#
# Declares default bash aliases for current project instance using a DB with
# 'arangodb' as driver.
#
# This file is dynamically included when the "hook" is triggered.
# @see cwt/bootstrap.sh
#
# Uses the docker exec interactive flag from 'docker-compose' extension.
# @see cwt/extensions/docker-compose/cwt/pre_bootstrap.docker-compose.hook.sh
#

# In order to support multi-db projects, those aliases must target the proper
# service depending on the currently selected DB_ID.
# This hook will be called once during bootstrap, then once more during db_set()
# where a local variable may target the correct service.
# -> Use the read-only global value if the service name was not overridden in
# u_db_set().
# @see cwt/extensions/db/db.inc.sh
# @see cwt/extensions/mysql/cwt/global.docker-compose.vars.sh
if [[ -z "$dc_db_service_name" ]]; then
  dc_db_service_name="${ARANGODB_SNAME:=arangodb}"
fi

alias arangosh="docker compose exec $DC_TTY $dc_db_service_name arangosh"
