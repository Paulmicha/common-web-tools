#!/usr/bin/env bash

##
# Implements hook -s 'instance' -a 'wait_for' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Wait until the database container accepts connections. Examples :
# See https://github.com/wodby/docker4drupal/blob/master/tests/8/run.sh
# See https://github.com/wodby/mariadb/blob/master/10/bin/actions.mk
# See https://github.com/wodby/alpine/blob/master/bin/wait_for
# @see cwt/utilities/shell.sh
# @see cwt/extensions/docker-compose/instance/start.docker-compose.hook.sh
# @see cwt/extensions/docker-compose/instance/instance.inc.sh
# @see cwt/instance/start.sh
#
# Uses bash aliases defined for mariadb (mysql).
# @see cwt/extensions/mysql/cwt/alias.docker-compose.hook.sh
#

# All databases information is already loaded at this point.
# @see cwt/extensions/db/instance/pre_start.hook.sh
# So all we have to do here is to check that every *MySQL* database is ready.
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

  case "${!uppercase}" in 'mysql')
    # We still have to call u_db_set() again for aliases targeting specific
    # docker-compose services.
    u_db_set "$db_id"

    wait_for "MySQL '$db_id' db" \
      "mysqladmin --user='$DB_ADMIN_USER' --password='$DB_ADMIN_PASS' --host='$DB_HOST' --port=$DB_PORT status &> /dev/null"
  esac
done
