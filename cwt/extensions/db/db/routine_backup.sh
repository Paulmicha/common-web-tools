#!/usr/bin/env bash

##
# Routine local DB dump (backup).
#
# The dump file path will be determined by the following globals :
#   - CWT_DB_DUMPS_BASE_PATH
#   - CWT_DB_DUMPS_LOCAL_PATTERN
#
# @see cwt/extensions/db/global.vars.sh
#
# @param 1 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   make db-routine-backup
#   make db-routine-backup 'custom_db_id'
#   # Or :
#   cwt/extensions/db/db/routine_backup.sh
#   cwt/extensions/db/db/routine_backup.sh 'custom_db_id'
#
#   # Resulting dump file path example :
#   # data/db-dumps/local/default/2024-08-08.17-25-29_local-default.paul.sql
#

. cwt/bootstrap.sh

# @see cwt/extensions/db/db.inc.sh
u_db_routine_backup $@
