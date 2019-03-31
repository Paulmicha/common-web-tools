#!/usr/bin/env bash

##
# Gets the most recent local instance DB dump.
#
# Optionally creates a new routine dump first.
#
# @param 1 [optional] String : pass 'new' to create new dump instead of
#   returning most recent among existing local DB dump files.
#
# @example
#   make db-get-dump
#   make db-get-dump new
#   # Or :
#   cwt/extensions/db/db/get_dump.sh
#   cwt/extensions/db/db/get_dump.sh new
#

. cwt/bootstrap.sh
u_db_get_dump $@
