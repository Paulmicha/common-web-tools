#!/usr/bin/env bash

##
# Implements u_hook_most_specific -s 'db' -a 'dump' -v 'DB_DRIVER HOST_TYPE INSTANCE_TYPE'
#
# This file is dynamically included when the "hook" is triggered.
# @see u_db_dump() in cwt/extensions/db/db.inc.sh
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
#   make db-backup
#   # Or :
#   cwt/extensions/db/db/dump.sh
#

# Prereq check :
# The output path (resulting file) "$db_dump_file" MUST be defined.
if [[ -z "$db_dump_file" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: the output path (resulting file) is not defined." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

u_fs_relative_path "$db_dump_file"

echo "Creating $DB_ID DB $DB_DRIVER dump '$relative_path' ..."

# Drush does not support dumping all DB, and this hook is not meant to do the
# looping on all DB IDs.
case "$DB_NAME" in '*')
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: must dump only 1 DB at a time." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
esac

drush sql-dump \
  --structure-tables-key='common' \
  --result-file="$db_dump_file" \
  --gzip

echo "Creating $DB_ID DB $DB_DRIVER dump '$relative_path' : done."
