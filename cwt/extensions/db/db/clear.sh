#!/usr/bin/env bash

##
# [abstract] Clears (empties) database.
#
# @param 1 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# This script provides an entry point for triggering a specific hook. "Abstract"
# means that this extension doesn't provide any actual implementation for this
# functionality. In order for this script to have any effect, it is necessary
# to use an extension that does. E.g. :
#
# @see cwt/extensions/mysql
# @see cwt/extensions/pgsql
#
# @example
#   make db-clear
#   make db-clear 'custom_db_id'
#   # Or :
#   cwt/extensions/db/db/clear.sh
#   cwt/extensions/db/db/clear.sh 'custom_db_id'
#

. cwt/bootstrap.sh

# @see cwt/extensions/db/db.inc.sh
u_db_clear $@
