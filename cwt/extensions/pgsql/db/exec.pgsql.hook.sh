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

# PostgreSQL utilities use the environment variables supported by libpq.
# See https://www.postgresql.org/docs/current/libpq-envars.html
PGPASSWORD="$DB_PASS"

# TODO [wip] handle the case where the database is not specified.
case "$DB_NAME" in '*')
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: multi-DB imports or queries not targeting any particular database are not supported at this point." >&2
  echo "-> Aborting (3)." >&2
  echo >&2
  exit 3
esac

psql \
  -U "$DB_USER" \
  -h "$DB_HOST" \
  -p "$DB_PORT" \
  -d "$DB_NAME" \
  -f "$db_dump_file"

if [[ $? -ne 0 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: unable to exec the queries in file '$db_dump_file' into $DB_DRIVER DB '$DB_NAME'." >&2
  echo "-> Aborting (2)." >&2
  echo >&2
  exit 2
fi
