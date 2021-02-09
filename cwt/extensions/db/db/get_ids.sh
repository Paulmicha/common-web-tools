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

db_ids=()
u_db_get_ids

echo "Here are all the database IDs defined in this project instance :"

for db_id in "${db_ids[@]}"; do
  echo " - $db_id"
done
