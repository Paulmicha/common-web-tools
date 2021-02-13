#!/usr/bin/env bash

##
# Implements u_hook_most_specific -s 'db' -a 'exists' -v 'DB_DRIVER HOST_TYPE INSTANCE_TYPE'.
#
# @requires the following var in calling scope :
# @var db_exists
#
# @see u_db_exists() in cwt/extensions/db/db.inc.sh
#
# @example
#   if u_db_exists 'my_db_name'; then
#     echo "Ok, 'my_db_name' exists."
#   else
#     echo "Error : 'my_db_name' does not exist (or I do not have permission to access it)."
#   fi
#

# Debug.
# echo "Test if database '${p_db_name}' exists (user=$DB_USER, password="$DB_PASS", host="$DB_HOST", port="$DB_PORT")..."

# See https://stackoverflow.com/a/32084118
if psql -lqtA \
  -U "$DB_USER" \
  -h "$DB_HOST" \
  -p "$DB_PORT" \
  -d "$DB_NAME" \
    | grep -q "^$p_db_name|"
then
  db_exists='true'
else
  db_exists='false'
fi
