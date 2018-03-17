#!/usr/bin/env bash

##
# Implements hook -s 'db' -a 'backup'.
#
# This file is dynamically included when the "hook" is triggered.
#
# @requires cwt/db/_dump_vars.shared.sh
#
# This script uses the following optional variable, if defined in calling scope :
# - DB_DUMP_NO_DATA_TABLES
#

dump_op='backup'
. cwt/db/_dump_vars.shared.sh

# Ensures DB dumps dir is writeable.
chmod +w "$DB_DUMP_BASE_PATH" -R
check_chmod="$?"
if [[ "$check_chmod" != 0 ]]; then
  echo
  echo "Error in $BASH_SOURCE line $LINENO: chmod +w $DB_DUMP_BASE_PATH -R exited with non-zero status ($check_chmod)."
  echo "-> Aborting (4)."
  echo
  exit 4
fi

# Ensures the current dump dir exists + is writeable.
if [ ! -d "$DB_DUMP_BASE_PATH/$DUMP_DIR" ]; then
  mkdir -p "$DB_DUMP_BASE_PATH/$DUMP_DIR"
  check_mkdir="$?"
  if [[ "$check_mkdir" != 0 ]]; then
    echo
    echo "Error in $BASH_SOURCE line $LINENO: mkdir -p '$DB_DUMP_BASE_PATH/$DUMP_DIR' exited with non-zero status ($check_mkdir)."
    echo "-> Aborting (5)."
    echo
    exit 5
  fi
  chmod +w "$DB_DUMP_BASE_PATH/$DUMP_DIR" -R
fi

# Ensures ownership.
# TODO avoid hardcoded user (see docker-compose exec --user 82 call below).
chown 82:82 "$DB_DUMP_BASE_PATH" -R
check_chown="$?"
if [[ "$check_chown" != 0 ]]; then
  echo
  echo "Error in $BASH_SOURCE line $LINENO: chown 82:82 "$DB_DUMP_BASE_PATH" -R exited with non-zero status ($check_chown)."
  echo "-> Aborting (6)."
  echo
  exit 6
fi

echo "Creating backup DB dump using docker-compose ..."

# TODO for docker-compose stacks, we assume DB_HOST is the same as the container
# (= service) name -> separate using different vars ?
# NB : the command runs inside the DB container, so 'localhost' is hardcoded.
# TODO implement https://stackoverflow.com/questions/13593148/mysql-dump-exclude-some-table-data
# mysqldump --no-data db_name > export.sql
# mysqldump --no-create-info --ignore-table=db_name.table_name1 [--ignore-table=db_name.table_name2, ...] db_name >> export.sql
docker-compose exec --user 82 "$DB_HOST" sh -c "exec mysqldump --host=localhost --user=$DB_USERNAME --password=$DB_PASSWORD --port=$DB_PORT $DB_NAME > $DB_DUMP_CONTAINER_BASE_PATH/$DUMP_FILE"

if [[ ! -f "$DB_DUMP_BASE_PATH/$DUMP_FILE" ]]; then
  echo
  echo "Error in $BASH_SOURCE line $LINENO: file '$DB_DUMP_BASE_PATH/$DUMP_FILE' does not exist."
  echo "-> Aborting (7)."
  echo
  exit 7
fi

# Compress & remove uncompressed dump file.
tar czf "$DB_DUMP_BASE_PATH/$DUMP_FILE.tgz" "$DB_DUMP_BASE_PATH/$DUMP_FILE"
rm "$DB_DUMP_BASE_PATH/$DUMP_FILE"

# Copy over as last dump for quicker restores.
cp -f "$DB_DUMP_BASE_PATH/$DUMP_FILE.tgz" "$DB_DUMP_BASE_PATH/$DUMP_FILE_LAST.tgz"

echo "Creating backup DB dump using docker-compose : done."
echo
