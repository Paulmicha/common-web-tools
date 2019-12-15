#!/usr/bin/env bash

##
# Creates a routine DB dump backup + progressively deletes old DB dumps.
#
# @param 1 [optional] String : 'no-purge' to prevent automatic deletion of old
#   backups.
# @param 2 [optional] String : $DB_ID override.
#
# @example
#   make db-routine-backup
#   make db-routine-backup 'no-purge'
#   make db-routine-backup '' 'custom_db_id'
#   make db-routine-backup 'no-purge' 'custom_db_id'
#   # Or :
#   cwt/extensions/db/db/routine_backup.sh
#   cwt/extensions/db/db/routine_backup.sh 'no-purge'
#   cwt/extensions/db/db/routine_backup.sh '' 'custom_db_id'
#   cwt/extensions/db/db/routine_backup.sh 'no-purge' 'custom_db_id'
#

. cwt/bootstrap.sh
u_db_routine_backup "$@"
