#!/usr/bin/env bash

##
# Empties database + imports the most recent local dump file.
#
# @param 1 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
# @param 2 [optional] String : subfolder in DB dumps dir.
#   Defaults to 'local'.
# @param 3 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   make db-restore-last
#   make db-restore-last 'custom_db_id'
#   make db-restore-last 'custom_db_id' 'prod'
#   # Or :
#   cwt/extensions/db/db/restore_last.sh
#   cwt/extensions/db/db/restore_last.sh 'custom_db_id'
#   cwt/extensions/db/db/restore_last.sh 'custom_db_id' 'prod'
#

. cwt/bootstrap.sh

# @see cwt/extensions/db/db.inc.sh
u_db_restore_last $@
