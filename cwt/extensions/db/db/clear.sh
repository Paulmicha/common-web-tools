#!/usr/bin/env bash

##
# [abstract] Clears (empties) database.
#
# @param 1 [optional] String : $DB_NAME override.
#
# This script provides an entry point for triggering a specific hook. "Abstract"
# means that this extension doesn't provide any actual implementation for this
# functionality. In order for this script to have any effect, it is necessary
# to use an extension that does. E.g. :
# @see cwt/extensions/mysql
#
# @example
#   make db-clear
#   make db-clear 'custom_db_name'
#   # Or :
#   cwt/extensions/db/db/clear.sh
#   cwt/extensions/db/db/clear.sh 'custom_db_name'
#

. cwt/bootstrap.sh
u_db_clear "$@"
