#!/usr/bin/env bash

##
# [abstract] Ensure DB credentials are correct.
#
# @param 1 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   make db-ensure-creds
#   make db-ensure-creds 'custom_db_id'
#   # Or :
#   cwt/extensions/db/db/ensure_creds.sh
#   cwt/extensions/db/db/ensure_creds.sh 'custom_db_id'
#

. cwt/bootstrap.sh

# @see cwt/extensions/db/db.inc.sh
u_db_ensure_creds $@
