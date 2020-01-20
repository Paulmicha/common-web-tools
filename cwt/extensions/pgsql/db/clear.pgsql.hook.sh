#!/usr/bin/env bash

##
# Implements u_hook_most_specific -s 'db' -a 'clear' -v 'DB_DRIVER HOST_TYPE INSTANCE_TYPE'
#
# This file is dynamically included when the "hook" is triggered.
# @see u_db_import() in cwt/extensions/db/db.inc.sh
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

# PostgreSQL utilities use the environment variables supported by libpq.
# See https://www.postgresql.org/docs/current/libpq-envars.html
PGPASSWORD="$DB_PASS"

# 1. Clears views (if any).
views_list=$(psql \
  -U "$DB_USER" \
  -h "$DB_HOST" \
  -p "$DB_PORT" \
  -d "$DB_NAME" \
  -t \
  --command "SELECT string_agg(table_name, ',') FROM information_schema.tables WHERE table_schema='public' AND table_type='VIEW'")

if [[ -n "$views_list" ]]; then
  psql \
    -U "$DB_USER" \
    -h "$DB_HOST" \
    -p "$DB_PORT" \
    -d "$DB_NAME" \
    -t \
    --command "DROP VIEW IF EXISTS $views_list CASCADE"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: unable to clear views in $DB_DRIVER DB '$DB_NAME'." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi
fi

# 2. Clears tables.
tables_list=$(psql \
  -U "$DB_USER" \
  -h "$DB_HOST" \
  -p "$DB_PORT" \
  -d "$DB_NAME" \
  -t \
  --command "SELECT string_agg(table_name, ',') FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE'")

if [[ -n "$views_list" ]]; then
  psql \
    -U "$DB_USER" \
    -h "$DB_HOST" \
    -p "$DB_PORT" \
    -d "$DB_NAME" \
    -t \
    --command "DROP TABLE IF EXISTS $tables_list CASCADE"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: unable to clear tables in $DB_DRIVER DB '$DB_NAME'." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi
fi
