#!/usr/bin/env bash

##
# Empties database + imports the last dump file.
#
# @param 1 [optional] String : $DB_NAME override.
#
# @example
#   cwt/extensions/db/db/restore_last.sh
#   cwt/extensions/db/db/restore_last.sh 'custom_db_name'
#

. cwt/bootstrap.sh
u_db_restore_last "$@"
