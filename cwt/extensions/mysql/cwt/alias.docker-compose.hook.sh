#!/usr/bin/env bash

##
# Implements hook -s 'cwt' -a 'alias' -v 'PROVISION_USING'.
#
# Declares default bash aliases for current project instance using mysql.
#
# This file is dynamically included when the "hook" is triggered.
# @see cwt/bootstrap.sh
#
# Uses the docker exec interactive flag from 'docker-compose' extension.
# @see cwt/extensions/docker-compose/cwt/pre_bootstrap.docker-compose.hook.sh
#
# In order to support multi-db projects, those aliases must target the proper
# service depending on the currently selected DB_ID.
#
# This hook will be called once during bootstrap, then once more during "db set"
# where a local variable may be used to overwrite those aliases in order to
# target the correct service.
#
# By default, the target container name will be the DB_HOST value.
#
# @see u_db_set() in cwt/extensions/db/db.inc.sh
#

if [[ -z "$dc_db_service_name" ]]; then
  dc_db_service_name="$DB_HOST"
fi

if [[ -n "$dc_db_service_name" ]]; then
  alias mysql="docker compose exec $DC_TTY $dc_db_service_name mysql"
  alias mysqldump="docker compose exec $DC_TTY $dc_db_service_name mysqldump"
  alias mysqladmin="docker compose exec $DC_TTY $dc_db_service_name mysqladmin"
  alias mysqlcheck="docker compose exec $DC_TTY $dc_db_service_name mysqlcheck"
  alias mysql_upgrade="docker compose exec $DC_TTY $dc_db_service_name mysql_upgrade"

  # Debug.
  # echo "aliases set or updated :"
  # echo "  mysql = docker compose exec $DC_TTY $dc_db_service_name mysql"
  # echo "  mysqldump = docker compose exec $DC_TTY $dc_db_service_name mysqldump"
  # echo "  mysqladmin = docker compose exec $DC_TTY $dc_db_service_name mysqladmin"
  # echo "  mysqlcheck = docker compose exec $DC_TTY $dc_db_service_name mysqlcheck"
  # echo "  mysql_upgrade = docker compose exec $DC_TTY $dc_db_service_name mysql_upgrade"
  # echo
fi
