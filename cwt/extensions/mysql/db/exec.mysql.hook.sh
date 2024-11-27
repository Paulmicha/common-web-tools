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

# TODO [wip] debug : no idea why some dump files begin like :
# 2024-08-07.16-31-35_service_foobar.comsql0000644000175000017500367165423314654745644024306 0ustar  sitesite-- MySQL dump 10.19  Distrib 10.3.39-MariaDB, for debian-linux-gnu (x86_64)
# --
# -- Host: service-db    Database: foobar-db-name
# -- ------------------------------------------------------
# (snip)
# Workaround : trim any initial lines containing '--' but not beginning with '--'.
# @see cwt/extensions/mysql/db/dump.mysql.hook.sh
dump_first_line="$(head -1 $db_dump_file)"

if [[ -n "$dump_first_line" ]]; then
  case "$dump_first_line" in *'--'*)
    if [[ "${dump_first_line:0:1}" != '-' ]]; then
      sed -i '1d' "$db_dump_file"
    fi
  esac
fi

# Update 2024/08/16 - use the --binary-mode by default for error :
# ERROR at line 1047: ASCII '\0' appeared in the statement, but this is not
# allowed unless option --binary-mode is enabled and mysql is run in
# non-interactive mode.
case "$DB_NAME" in
  '*')
    mysql --binary-mode --default_character_set="$SQL_CHARSET" \
      --user="$DB_USER" \
      --password="$DB_PASS" \
      --host="$DB_HOST" \
      --port="$DB_PORT" \
      -B < "$db_dump_file"
    ;;
  *)
    mysql --binary-mode --default_character_set="$SQL_CHARSET" \
      --user="$DB_USER" \
      --password="$DB_PASS" \
      --host="$DB_HOST" \
      --port="$DB_PORT" \
      -B \
      "$DB_NAME" < "$db_dump_file"
    ;;
esac

# Update 2024/08/16 - retry without the '--binary-mode' option.
if [[ $? -ne 0 ]]; then
  echo "Retry without --binary-mode ..."

  . cwt/extensions/db/db/clear.sh

  case "$DB_NAME" in
    '*')
      mysql --default_character_set="$SQL_CHARSET" \
        --user="$DB_USER" \
        --password="$DB_PASS" \
        --host="$DB_HOST" \
        --port="$DB_PORT" \
        -B < "$db_dump_file"
      ;;
    *)
      mysql --default_character_set="$SQL_CHARSET" \
        --user="$DB_USER" \
        --password="$DB_PASS" \
        --host="$DB_HOST" \
        --port="$DB_PORT" \
        -B \
        "$DB_NAME" < "$db_dump_file"
      ;;
  esac

  # Fail if workaround didn't work.
  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: unable to exec the queries in file '$db_dump_file' into $DB_DRIVER DB '$DB_NAME'." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi

  echo "Retry without --binary-mode : done."
fi
