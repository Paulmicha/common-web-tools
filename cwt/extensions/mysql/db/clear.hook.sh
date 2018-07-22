#!/usr/bin/env bash

##
# Implements u_hook_most_specific -s 'db' -a 'clear' -v 'PROVISION_USING'
#
# This file is dynamically included when the "hook" is triggered.
# @see u_db_import() in cwt/extensions/db/db.inc.sh
#
# @example
#   make db-clear
#   # Or :
#   cwt/extensions/db/db/clear.sh
#

# This generates a query that drops all tables, then executes it.
mysqldump --no-data --add-drop-table \
  --user="$DB_USERNAME" \
  --password="$DB_PASSWORD" \
  --host="$DB_HOST" \
  --port="$DB_PORT" \
  "$DB_NAME" \
  | grep ^DROP \
  | mysql \
    --user="$DB_USERNAME" \
    --password="$DB_PASSWORD" \
    --host="$DB_HOST" \
    --port="$DB_PORT"

if [[ $? -ne 0 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: unable to empty (= clear = flush) all existing data in DB '$DB_NAME'." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi
