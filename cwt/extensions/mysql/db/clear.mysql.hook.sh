#!/usr/bin/env bash

##
# Implements u_hook_most_specific -s 'db' -a 'clear' -v 'DB_DRIVER HOST_TYPE INSTANCE_TYPE'
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
#   make db-clear
#   # Or :
#   cwt/extensions/db/db/clear.sh
#

echo "Clearing DB $DB_NAME from $DB_HOST ..."

# This generates a query that drops all tables, then executes it.
# Update 2024/08/16 - Workaround errors like :
# ERROR 1451 (23000) at line 7: Cannot delete or update a parent row: a foreign
# key constraint fails
# @link https://stackoverflow.com/a/18889743/2592338
mysqldump --no-data --add-drop-table \
  --user="$DB_USER" \
  --password="$DB_PASS" \
  --host="$DB_HOST" \
  --port="$DB_PORT" \
  "$DB_NAME" \
  | grep -e '^DROP \| FOREIGN_KEY_CHECKS' \
  | mysql \
    --user="$DB_USER" \
    --password="$DB_PASS" \
    --host="$DB_HOST" \
    --port="$DB_PORT" \
    "$DB_NAME"

if [[ $? -ne 0 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: unable to clear existing data in $DB_DRIVER DB '$DB_NAME'." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

echo "Clearing DB $DB_NAME from $DB_HOST : done."
