#!/usr/bin/env bash

##
# Implements hook -s 'db' -a 'restore'.
#
# This file is dynamically included when the "hook" is triggered.
#
# @requires cwt/db/_dump_vars.shared.sh
# @requires the following additional globals in calling scope :
# - DB_DUMP_BASE_PATH
# - DB_DUMP_CONTAINER_BASE_PATH
#

dump_op='restore'
. cwt/db/_dump_vars.shared.sh

# If the "last" dump exists, use it.
# TODO implement optional arg to specify which dump to restore ?
# -> meanwhile, require "last" dump.
if [[ ! -f "$DB_DUMP_BASE_PATH/$DUMP_FILE_LAST.tgz" ]]; then
  echo
  echo "Error in $BASH_SOURCE line $LINENO: file '$DB_DUMP_BASE_PATH/$DUMP_FILE_LAST.tgz' does not exist."
  echo "-> aborting (4)."
  echo
  exit 4
fi

echo "Restoring backup DB dump using docker-compose ..."

# Uncompress + restore last dump + remove uncompressed temporary dump file.
tar xzf "$DB_DUMP_BASE_PATH/$DUMP_FILE_LAST.tgz"
# TODO for docker-compose stacks, we assume DB_HOST is the same as the container
# (= service) name -> separate using different vars ?
# NB : the command runs inside the DB container, so 'localhost' is hardcoded.
docker-compose exec "$DB_HOST" sh -c "exec mysqldump --host=localhost --user=$DB_USERNAME --password=$DB_PASSWORD --port=$DB_PORT --add-drop-table --no-data $DB_NAME | grep ^DROP | mysql -h localhost -u$DB_USERNAME -p$DB_PASSWORD $DB_NAME"
docker-compose exec "$DB_HOST" sh -c "exec mysql -h localhost -u$DB_USERNAME -p$DB_PASSWORD --default_character_set=utf8 $DB_NAME < $DB_DUMP_CONTAINER_BASE_PATH/$DUMP_FILE_LAST"
rm "$DB_DUMP_BASE_PATH/$DUMP_FILE_LAST"

echo "Restoring backup DB dump using docker-compose : done."
echo
