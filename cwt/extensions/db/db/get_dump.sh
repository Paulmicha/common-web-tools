#!/usr/bin/env bash

##
# Gets local instance DB dump filepaths.
#
# Optionally creates a new routine dump first.
#
# @param 1 [optional] String : Pass 'new' to create immediately a new routine
#   dump and return its file path. Pass 'last' to return the most recent dump
#   file. Any other value is a "find" file name filter that will return a single
#   matching dump (the most recent in case there are several matches).
#   Defaults to 'last'.
# @param 2 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
# @param 3 [optional] String : subfolder in DB dumps dir.
#   Defaults to 'local'.
# @param 4 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   make db-get-dump
#   make db-get-dump new
#   make db-get-dump '*.foobar.com.gz'
#   make db-get-dump 'last' 'custom_db_id'
#   make db-get-dump 'last' 'custom_db_id' 'prod'
#   # Or :
#   cwt/extensions/db/db/get_dump.sh
#   cwt/extensions/db/db/get_dump.sh new
#   cwt/extensions/db/db/get_dump.sh '*.foobar.com.gz'
#   cwt/extensions/db/db/get_dump.sh 'last' 'custom_db_id'
#   cwt/extensions/db/db/get_dump.sh 'last' 'custom_db_id' 'prod'
#

. cwt/bootstrap.sh

# @see cwt/extensions/db/db.inc.sh
u_db_get_dump $@
