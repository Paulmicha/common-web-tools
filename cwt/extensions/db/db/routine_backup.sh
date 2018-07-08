#!/usr/bin/env bash

##
# Creates a routine DB dump backup + progressively deletes old DB dumps.
#
# @param 1 [optional] String : 'no-purge' to prevent automatic deletion of old
#   backups.
# @param 2 [optional] String : $DB_NAME override.
#
# @example
#   cwt/extensions/db/db/routine_backup.sh
#   cwt/extensions/db/db/routine_backup.sh 'no-purge'
#   cwt/extensions/db/db/routine_backup.sh '' 'custom_db_name'
#   cwt/extensions/db/db/routine_backup.sh 'no-purge' 'custom_db_name'
#

. cwt/bootstrap.sh
u_db_routine_backup "$@"
