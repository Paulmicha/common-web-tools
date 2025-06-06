#!/usr/bin/env bash

##
# Implements u_hook_most_specific -s 'db' -a 'query' -v 'DB_DRIVER DB_ID INSTANCE_TYPE PROVISION_USING'
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
#   cwt/extensions/db/db/query.sh 'UPDATE users SET name = "foobar" WHERE email = "foo@bar.com";'
#

case "$DB_NAME" in
  '*')
    mysql --default_character_set="$SQL_CHARSET" \
      --user="$DB_USER" \
      --password="$DB_PASS" \
      --host="$DB_HOST" \
      --port="$DB_PORT" \
      -B <<< "$p_query"
    ;;
  *)
    mysql --default_character_set="$SQL_CHARSET" \
      --user="$DB_USER" \
      --password="$DB_PASS" \
      --host="$DB_HOST" \
      --port="$DB_PORT" \
      -B \
      "$DB_NAME" <<< "$p_query"
    ;;
esac

if [[ $? -ne 0 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: query failed." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi
