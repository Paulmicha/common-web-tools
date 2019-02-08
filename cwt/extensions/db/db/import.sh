#!/usr/bin/env bash

##
# [abstract] Imports (= executes) given file into database.
#
# @param 1 String : the dump file path.
# @param 2 [optional] String : $DB_NAME override.
#
# This script provides an entry point for triggering a specific hook. "Abstract"
# means that this extension doesn't provide any actual implementation for this
# functionality. In order for this script to have any effect, it is necessary
# to use an extension that does. E.g. :
# @see cwt/extensions/mysql
#
# @example
#   make db-import '/path/to/dump/file.sql'
#   make db-import '/path/to/dump/file.sql' 'custom_db_name'
#   # Or :
#   cwt/extensions/db/db/import.sh '/path/to/dump/file.sql'
#   cwt/extensions/db/db/import.sh '/path/to/dump/file.sql' 'custom_db_name'
#

. cwt/bootstrap.sh
u_db_import "$@"
