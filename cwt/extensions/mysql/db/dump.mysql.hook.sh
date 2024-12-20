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

# Support excluding data for specific tables.
# Only deal with single-database exports. See if it's desirable to deal with the
# all-db-at-once scenario here too, eventually.
# See https://github.com/wodby/mariadb/blob/master/10/bin/backup
skip_data=()
if [[ -n "$DB_TABLES_SKIP_DATA" ]] && [[ "$DB_NAME" != '*' ]]; then
  IFS=',' read -ra ADDR <<< "$DB_TABLES_SKIP_DATA"
  for table in "${ADDR[@]}"; do
    if echo "${table}" | grep -q '*'; then
      table="${table//'*'/'%'}"
      out=$(mysql --silent --user="$DB_USER" --password="$DB_PASS" --host="$DB_HOST" --port="$DB_PORT" -e "SHOW TABLES LIKE '${table}'" "${DB_NAME}")
      tables=(${out//$'\n'/ })
      for t in "${tables[@]}"; do
        skip_data+=("--ignore-table=${DB_NAME}.${t}")
      done
    else
      skip_data+=("--ignore-table=${DB_NAME}.${table}")
    fi
  done
fi

u_fs_relative_path "$db_dump_file"
echo "Creating $DB_ID DB $DB_DRIVER dump '$relative_path' ..."

# In order to support excluding data for specific tables, export the structure
# alone first, then the data (optionally excluding said tables).
# See https://github.com/wodby/mariadb/blob/master/10/bin/backup

mysqldump_last_arg="$DB_NAME"
case "$DB_NAME" in '*')
  mysqldump_last_arg="--all-databases"
esac

# Debug
# echo "mysqldump --user='$DB_USER' --password='***' --host='$DB_HOST' --port='$DB_PORT' --single-transaction --no-data --allow-keywords --skip-triggers $mysqldump_last_arg > '$db_dump_file'"

# 1. Structure.
mysqldump \
  --user="$DB_USER" \
  --password="$DB_PASS" \
  --host="$DB_HOST" \
  --port="$DB_PORT" \
  --single-transaction --no-data --allow-keywords --skip-triggers \
  $mysqldump_last_arg > "$db_dump_file"

if [[ $? -ne 0 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: unable to backup $DB_DRIVER DB '$DB_NAME' to dump file '$db_dump_file'." >&2
  echo "-> Aborting (2)." >&2
  echo >&2
  exit 2
fi

# Debug
# echo "mysqldump --user='$DB_USER' --password='***' --host='$DB_HOST' --port='$DB_PORT' --single-transaction --no-create-info --allow-keywords ${skip_data[@]} $mysqldump_last_arg >> '$db_dump_file'"

# 2. Data.
mysqldump \
  --user="$DB_USER" \
  --password="$DB_PASS" \
  --host="$DB_HOST" \
  --port="$DB_PORT" \
  --single-transaction --no-create-info --allow-keywords "${skip_data[@]}" \
  $mysqldump_last_arg >> "$db_dump_file"

if [[ $? -ne 0 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: unable to backup $DB_DRIVER DB '$DB_NAME' to dump file '$db_dump_file'." >&2
  echo "-> Aborting (3)." >&2
  echo >&2
  exit 3
fi

echo "Creating $DB_ID DB $DB_DRIVER dump '$relative_path' : done."
