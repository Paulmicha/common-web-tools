#!/usr/bin/env bash

##
# Implements u_hook_most_specific -s 'db' -a 'backup' -v 'DB_DRIVER HOST_TYPE INSTANCE_TYPE'
#
# This file is dynamically included when the "hook" is triggered.
# @see u_db_backup() in cwt/extensions/db/db.inc.sh
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
# @see u_db_get_credentials() in cwt/extensions/db/db.inc.sh
#
# @example
#   make db-backup
#   # Or :
#   cwt/extensions/db/db/backup.sh
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

# Support excluding data for specific tables.
# See https://github.com/wodby/postgres/blob/master/bin/backup
skip_data=''
if [[ -n "$DB_TABLES_SKIP_DATA" ]]; then
  for table in $DB_TABLES_SKIP_DATA; do
    # TODO [evol] Support wildcards - e.g. "cache*" to exclude all table names
    # beginning with 'cache'.
    skip_data+="--exclude-table-data=$table "
  done
fi

u_fs_relative_path "$db_dump_file"
echo "Creating $DB_ID DB $DB_DRIVER dump '$relative_path' ..."

# PostgreSQL utilities use the environment variables supported by libpq.
# See https://www.postgresql.org/docs/current/libpq-envars.html
PGPASSWORD="$DB_PASS"

# Use nice + ionice to tune down server ressources used for backup.
# See https://github.com/wodby/postgres/blob/master/bin/backup
# + https://github.com/wodby/postgres/blob/master/bin/actions.mk
nice -n10 ionice -c2 -n7 \
  pg_dump "$skip_data" \
    -U"$DB_USER" \
    -h"$DB_HOST" \
    -p"$DB_PORT" \
      "$DB_NAME" > "$db_dump_file"

if [[ $? -ne 0 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: unable to backup DB '$DB_NAME' to dump file '$db_dump_file'." >&2
  echo "-> Aborting (2)." >&2
  echo >&2
  exit 2
fi

echo "Creating $DB_ID DB $DB_DRIVER dump '$relative_path' : done."
