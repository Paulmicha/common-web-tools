#!/usr/bin/env bash

##
# Implements u_hook_most_specific -s 'db' -a 'import' -v 'PROVISION_USING'
#
# This file is dynamically included when the "hook" is triggered.
# @see u_db_import() in cwt/extensions/db/db.inc.sh
#

# Prereq check :
# The source file "$db_dump_file" MUST exist and be accessible.
if [[ ! -f "$db_dump_file" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: the DB dump file '$db_dump_file' is missing or inaccessible." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

# Prereq : empty (= clear = flush) all existing data in target DB.
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
  echo "Error in $BASH_SOURCE line $LINENO: unable to empty (= clear = flush) all existing data in target DB '$DB_NAME'." >&2
  echo "-> Aborting (2)." >&2
  echo >&2
  exit 2
fi

# TODO [wip] handle 'default_character_set' separately from base extension ?
# @see u_db_get_credentials() in cwt/extensions/db/db.inc.sh
mysql --default_character_set=utf8 \
  --user="$DB_USERNAME" \
  --password="$DB_PASSWORD" \
  --host="$DB_HOST" \
  --port="$DB_PORT" \
  "$DB_NAME" < "$db_dump_file"

if [[ $? -ne 0 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: unable to import dump file '$db_dump_file' into DB '$DB_NAME'." >&2
  echo "-> Aborting (3)." >&2
  echo >&2
  exit 3
fi
