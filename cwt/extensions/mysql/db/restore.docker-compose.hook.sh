#!/usr/bin/env bash

##
# Implements hook -s 'db' -a 'restore' -v 'PROVISION_USING'.
#
# This file is dynamically included when the "hook" is triggered.
#
# @requires cwt/extensions/mysql/db/_dump_vars.shared.sh
# @requires the following additional globals in calling scope :
# - DB_DUMP_BASE_PATH
# - DB_DUMP_CONTAINER_BASE_PATH
# - [optional] DUMP_TO_RESTORE # <- Overrides default dump to restore if set.
#

dump_op='restore'
. cwt/extensions/mysql/db/_dump_vars.shared.sh

# Default file to restore is "the last one" unless provided via a preset variable.
dump_path="$DB_DUMP_BASE_PATH/$DUMP_FILE_LAST"
if [[ -n "$DUMP_TO_RESTORE" ]]; then
  dump_path="$DB_DUMP_BASE_PATH/$DUMP_TO_RESTORE"
fi

# If the "last" dump exists, use it.
# TODO implement optional arg to specify which dump to restore ?
# -> meanwhile, require "last" dump.
if [[ ! -f "${dump_path}.tgz" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: file '${dump_path}.tgz' does not exist." >&2
  echo "-> aborting (4)." >&2
  echo >&2
  exit 4
fi

echo "Restoring backup DB dump using docker-compose ..."

# Uncompress + restore last dump + remove uncompressed temporary dump file.
tar xzf "${dump_path}.tgz" -C "$DB_DUMP_BASE_PATH"

check_tar=$?
if [ $check_tar -ne 0 ]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: tar exited with non-zero status ($check_tar)." >&2
  echo "-> Aborting (5)." >&2
  echo >&2
  exit 5
fi

# Exception to the rule below :
# when a DB dump is created using our helper scripts, the uncompressed file name
# should be "last.sql" (and NOT the same name as the TAR archive).
# -> handle as fallback here.
if [[ ! -f "${dump_path}" ]]; then
  dump_path="$DB_DUMP_BASE_PATH/$DUMP_FILE_LAST"
fi

if [[ ! -f "${dump_path}" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: file '${dump_path}' does not exist." >&2
  echo "-> Aborting (6)." >&2
  echo >&2
  exit 6
fi

# Ensures ownership.
# TODO avoid hardcoded user (see docker-compose exec --user 82 call below).
chown 82:82 "$DB_DUMP_BASE_PATH" -R
check_chown=$?
if [ $check_chown -ne 0 ]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: chown 82:82 "$DB_DUMP_BASE_PATH" -R exited with non-zero status ($check_chown)." >&2
  echo "-> Aborting (7)." >&2
  echo >&2
  exit 7
fi

# TODO for docker-compose stacks, we assume DB_HOST is the same as the container
# (= service) name -> separate using different vars ?
# NB : the command runs inside the DB container, so 'localhost' is hardcoded.

# TODO use this workaround below to support remote calls (non-TTY context).
# See https://github.com/docker/compose/issues/4290
# @see cwt/db/mysql_backup.docker-compose.hook.sh

docker-compose exec --user 82 "$DB_HOST" sh -c "exec mysqldump --host=localhost --user=$DB_USERNAME --password=$DB_PASSWORD --port=$DB_PORT --add-drop-table --no-data $DB_NAME | grep ^DROP | mysql -h localhost -u$DB_USERNAME -p$DB_PASSWORD $DB_NAME"

docker-compose exec --user 82 "$DB_HOST" sh -c "exec mysql -h localhost -u$DB_USERNAME -p$DB_PASSWORD --default_character_set=utf8 $DB_NAME < $DB_DUMP_CONTAINER_BASE_PATH/$DUMP_FILE_LAST"
rm "${dump_path}"

echo "Restoring backup DB dump using docker-compose : done."
echo
