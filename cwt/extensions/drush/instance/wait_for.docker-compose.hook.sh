#!/usr/bin/env bash

##
# Implements hook -s 'instance' -a 'wait_for' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#

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

  case "${!uppercase}" in 'drush')
    # We still have to call u_db_set() again for aliases targeting specific
    # docker-compose services.
    u_db_set "$db_id"

    # TODO [evol] seems difficult to fallback here as the other imp. target
    # specific drivers but drush can fallback to both, so for now, hardcoded.
    case "$DRUSH_DB_DRIVER_FALLBACK" in
      'mysql')
        wait_for "drush (MySQL) '$db_id' db" \
          "mysqladmin --user='$DB_ADMIN_USER' --password='$DB_ADMIN_PASS' --host='$DB_HOST' --port=$DB_PORT status &> /dev/null"
        ;;

      'pgsql')
        wait_for "drush (PgSQL) '$db_id' db" \
          "pg_isready -h$DB_HOST -p$DB_PORT -U$DB_USER -d$DB_NAME -t1 &> /dev/null"
        ;;
    esac
  esac
done
