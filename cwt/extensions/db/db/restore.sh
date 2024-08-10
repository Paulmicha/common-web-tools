#!/usr/bin/env bash

##
# Empties database + imports given dump file.
#
# @param 1 String : the dump file path.
# @param 2 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
#
# @example
#   make db-restore 'path/to/dump/file.sql'
#   make db-restore 'path/to/dump/file.sql' 'custom_db_id'
#   # Or :
#   cwt/extensions/db/db/restore.sh 'path/to/dump/file.sql'
#   cwt/extensions/db/db/restore.sh 'path/to/dump/file.sql' 'custom_db_id'
#

. cwt/bootstrap.sh

# @see cwt/extensions/db/db.inc.sh
u_db_restore $@
