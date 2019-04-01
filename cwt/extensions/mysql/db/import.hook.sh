#!/usr/bin/env bash

##
# Implements u_hook_most_specific -s 'db' -a 'import' -v 'PROVISION_USING'
#
# This file is dynamically included when the "hook" is triggered.
# @see u_db_import() in cwt/extensions/db/db.inc.sh
#
# @example
#   make db-import
#   # Or :
#   cwt/extensions/db/db/import.sh
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

# Prevent MySQL ERROR 1470 (HY000) String is too long for user name - should
# be no longer than 16 characters.
# Warning : this creates naming collision risks (considered edge case).
mysql_db_username="${DB_USERNAME:0:16}"

mysql --default_character_set="$DB_CHARSET" \
  --user="$mysql_db_username" \
  --password="$DB_PASSWORD" \
  --host="$DB_HOST" \
  --port="$DB_PORT" \
  -B \
  "$DB_NAME" < "$db_dump_file"

if [[ $? -ne 0 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: unable to import dump file '$db_dump_file' into DB '$DB_NAME'." >&2
  echo "-> Aborting (3)." >&2
  echo >&2
  exit 3
fi
