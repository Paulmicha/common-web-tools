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
check_chmod=$?
if [ $check_chmod -ne 0 ]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: chmod +w $DB_DUMP_BASE_PATH -R exited with non-zero status ($check_chmod)." >&2
  echo "-> Aborting (4)." >&2
  echo >&2
  exit 4
fi

# Ensures the current dump dir exists + is writeable.
if [ ! -d "$DB_DUMP_BASE_PATH/$DUMP_DIR" ]; then
  mkdir -p "$DB_DUMP_BASE_PATH/$DUMP_DIR"
  check_mkdir=$?
  if [ $check_mkdir -ne 0 ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: mkdir -p '$DB_DUMP_BASE_PATH/$DUMP_DIR' exited with non-zero status ($check_mkdir)." >&2
    echo "-> Aborting (5)." >&2
    echo >&2
    exit 5
  fi
  chmod +w "$DB_DUMP_BASE_PATH/$DUMP_DIR" -R
fi

# Ensures ownership.
# TODO avoid hardcoded user (see docker-compose exec --user 82 call below).
chown 82:82 "$DB_DUMP_BASE_PATH" -R
check_chown=$?
if [ $check_chown -ne 0 ]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: chown 82:82 "$DB_DUMP_BASE_PATH" -R exited with non-zero status ($check_chown)." >&2
  echo "-> Aborting (6)." >&2
  echo >&2
  exit 6
fi

echo "Creating backup DB dump using docker-compose ..."

# TODO for docker-compose stacks, we assume DB_HOST is the same as the container
# (= service) name -> separate using different vars ?
# NB : the command runs inside the DB container, so 'localhost' is hardcoded.
# TODO implement https://stackoverflow.com/questions/13593148/mysql-dump-exclude-some-table-data
# mysqldump --no-data db_name > export.sql
# mysqldump --no-create-info --ignore-table=db_name.table_name1 [--ignore-table=db_name.table_name2, ...] db_name >> export.sql

# docker-compose exec --user 82 "$DB_HOST" sh -c "exec mysqldump --host=localhost --user=$DB_USERNAME --password=$DB_PASSWORD --port=$DB_PORT $DB_NAME > $DB_DUMP_CONTAINER_BASE_PATH/$DUMP_FILE"

# See https://github.com/docker/compose/issues/5696 -> FAIL
#export COMPOSE_INTERACTIVE_NO_CLI=1
#docker-compose exec --user 82 "$DB_HOST" sh -c "exec mysqldump --host=localhost --user=$DB_USERNAME --password=$DB_PASSWORD --port=$DB_PORT $DB_NAME > $DB_DUMP_CONTAINER_BASE_PATH/$DUMP_FILE"
#docker-compose exec --user 82 "$DB_HOST" mysqldump --host=localhost --user=$DB_USERNAME --password=$DB_PASSWORD --port=$DB_PORT $DB_NAME > $DB_DUMP_BASE_PATH/$DUMP_FILE

# See https://github.com/docker/compose/issues/4290 -> OK
docker exec -i $(docker-compose ps -q "$DB_HOST") mysqldump --host=localhost --user="$DB_USERNAME" --password="$DB_PASSWORD" --port=$DB_PORT "$DB_NAME" > "$DB_DUMP_BASE_PATH/$DUMP_FILE"

if [ ! -f "$DB_DUMP_BASE_PATH/$DUMP_FILE" ]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: file '$DB_DUMP_BASE_PATH/$DUMP_FILE' does not exist." >&2
  echo "-> Aborting (7)." >&2
  echo >&2
  exit 7
fi

# Rename & compress & remove uncompressed dump file.
mv "$DB_DUMP_BASE_PATH/$DUMP_FILE" "$DB_DUMP_BASE_PATH/$DUMP_DIR/$DUMP_FILE_LAST"
tar czf "$DB_DUMP_BASE_PATH/$DUMP_FILE.tgz" -C "$DB_DUMP_BASE_PATH/$DUMP_DIR" "$DUMP_FILE_LAST"
rm "$DB_DUMP_BASE_PATH/$DUMP_DIR/$DUMP_FILE_LAST"

# Copy over as last dump for quicker restores.
cp -f "$DB_DUMP_BASE_PATH/$DUMP_FILE.tgz" "$DB_DUMP_BASE_PATH/$DUMP_FILE_LAST.tgz"

echo "Creating backup DB dump using docker-compose : done."
echo
