#!/usr/bin/env bash

##
# Empties database + imports given dump file.
#
# @param 1 String : the dump file path.
# @param 2 [optional] String : $DB_NAME override.
#
# @example
#   cwt/extensions/db/db/restore.sh '/path/to/dump/file.sql'
#

. cwt/bootstrap.sh
u_db_restore "$@"
