#!/usr/bin/env bash

##
# Empties database + imports the most recent dump file from any subfolder.
#
# @param 1 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   make db-restore-any
#   make db-restore-any 'custom_db_id'
#   # Or :
#   cwt/extensions/db/db/restore_any.sh
#   cwt/extensions/db/db/restore_any.sh 'custom_db_id'
#

. cwt/bootstrap.sh

# @see cwt/extensions/db/db.inc.sh
u_db_restore_any $@
