#!/usr/bin/env bash

##
# Gets local instance database ID(s).
#
# Prints all databse ID(s) declared in this project instance.
#
# @example
#   make db-get-ids
#   # Or :
#   cwt/extensions/db/db/get_ids.sh
#

. cwt/bootstrap.sh
u_db_set $@

echo "CWT_DB_IDS = '$CWT_DB_IDS'"
