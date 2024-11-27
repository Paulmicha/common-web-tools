#!/usr/bin/env bash

##
# Implements u_hook_most_specific -s 'db' -a 'exec' -v 'DB_DRIVER DB_ID INSTANCE_TYPE PROVISION_USING'
#
# This file is dynamically included when the "hook" is triggered.
# @see u_db_exec() in cwt/extensions/db/db.inc.sh
#
# The following variables are available here :
#   - DB_ID - defaults to 'default'.
#   - DB_DRIVER - defaults to 'mysql'.
#   - DB_HOST - defaults to 'localhost'.
#   - DB_PORT - defaults to '3306' or '5432' if DB_DRIVER is 'pgsql'.
#   - DB_NAME - defaults to "*".
#   - DB_USER - defaults to first 16 characters of DB_ID.
#   - DB_PASS - defaults to 14 random characters.
#   - DB_ADMIN_USER - defaults to DB_USER.
#   - DB_ADMIN_PASS - defaults to DB_PASS.
#   - DB_TABLES_SKIP_DATA - defaults to an empty string.
# @see u_db_set() in cwt/extensions/db/db.inc.sh
#
# @example
#   make db-exec
#   # Or :
#   cwt/extensions/db/db/exec.sh
#

# When using docker-compose (executing drush inside container), this yields :
# Error : "mysql: command not found".
# @see cwt/extensions/drush/cwt/alias.docker-compose.hook.sh
# $(drush sql:connect) < "$db_dump_file"

# So we need Docker compose paths conversion.
# -> use a dedicated (more specific) hook implementation :
# @see cwt/extensions/drush/db/exec.drush.docker-compose.hook.sh
drush sql:query --file="$db_dump_file"

if [[ $? -ne 0 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: unable to exec the queries in file '$db_dump_file' into $DB_DRIVER DB '$DB_NAME'." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi
