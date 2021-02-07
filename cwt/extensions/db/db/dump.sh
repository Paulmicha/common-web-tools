#!/usr/bin/env bash

##
# Creates a routine DB dump.
#
# @param 1 [optional] String : $DB_ID override.
#
# @example
#   make db-dump
#   make db-dump 'custom_db_id'
#   # Or :
#   cwt/extensions/db/db/dump.sh
#   cwt/extensions/db/db/dump.sh 'custom_db_id'
#

. cwt/bootstrap.sh
u_db_routine_backup "$@"
