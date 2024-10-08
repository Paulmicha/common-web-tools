#!/usr/bin/env bash

##
# Implements u_hook_most_specific -s 'db' -a 'create' -v 'DB_DRIVER HOST_TYPE INSTANCE_TYPE'.
#
# This file is dynamically included when the "hook" is triggered.
# @see u_db_create() in cwt/extensions/db/db.inc.sh
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
#   make db-create
#   # Or :
#   cwt/extensions/db/db/create.sh
#

echo "Creating $DB_ID $DB_DRIVER database '$DB_NAME' on $DB_HOST ..."

drush sql:create \
  --db-su="$DB_ADMIN_USER" \
  --db-su-pw="$DB_ADMIN_PASS" \
  --db-url="$DRUSH_DB_DRIVER_FALLBACK://$DB_USER:$DB_PASS@$DB_HOST/$DB_NAME" \
  -y

echo "Creating $DB_ID $DB_DRIVER database '$DB_NAME' on $DB_HOST : done."
