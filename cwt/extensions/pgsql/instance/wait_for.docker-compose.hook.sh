#!/usr/bin/env bash

##
# Implements hook -s 'instance' -a 'wait_for' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Wait until the database container accepts connections. Examples :
# See https://github.com/wodby/docker4drupal/blob/master/tests/8/run.sh
# See https://github.com/wodby/postgres/blob/master/bin/wait_for_postgres
# See https://github.com/wodby/alpine/blob/master/bin/wait_for
# @see cwt/utilities/shell.sh
# @see cwt/extensions/docker-compose/instance/start.docker-compose.hook.sh
# @see cwt/extensions/docker-compose/instance/instance.inc.sh
# @see cwt/instance/start.sh
#
# Uses bash aliases defined for postgres.
# @see cwt/extensions/pgsql/cwt/alias.docker-compose.hook.sh
#

# All databases information is already loaded at this point.
# @see cwt/extensions/db/instance/pre_start.hook.sh
# So all we have to do here is to check that every PgSQL database is ready.
db_ids=()
u_db_get_ids

for db_id in "${db_ids[@]}"; do
  # We need to make sure our database exists (i.e. has been previously
  # created) for the wait to make sense. Using a "registry" entry for now.
  # Update : this prevents to import initial dumps during setup
  # -> we can't depend on the DB existing for this check to work. Abort.
  # if ! u_db_is_flagged "$db_id"; then
  #   continue
  # fi

  u_str_uppercase "${db_id}_DB_DRIVER"

  case "${!uppercase}" in 'pgsql')
    # We still have to call u_db_set() again for aliases targeting specific
    # docker-compose services.
    u_db_set "$db_id"

    wait_for "PgSQL '$db_id' db" \
      "pg_isready -h$DB_HOST -p$DB_PORT -U$DB_USER -d$DB_NAME -t1 &> /dev/null"
  esac
done
