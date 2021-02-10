#!/usr/bin/env bash

##
# Gets local instance DB credentials (in fact, all DB information).
#
# @see u_db_set()
#
# Uses the following env. var. if it is defined in current shell scope to select
# which database credentials to load :
# - CWT_DB_ID
# This allows to operate on different databases from the same project instance.
# See also the first parameter to this function documented below.
#
# If CWT_DB_MODE is set to 'auto' or 'manual', the first call to this function
# will generate once the values for these globals.
# Subsequent calls to this function will then read said values from registry.
# @see cwt/instance/registry_set.sh
# @see cwt/instance/registry_get.sh
#
# @param 1 [optional] String : unique DB identifier. Defaults to 'default'.
#   Important note : DB_ID values are restricted to alphanumerical characters
#   and underscores (i.e. like variable names).
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#
# @example
#   # Prints out a recap of the 'default' DB credentials (unless CWT_DB_ID is
#   # set to another value in current shell scope).
#   make db-get-credentials
#   # Or :
#   cwt/extensions/db/db/get_credentials.sh
#
#   # Prints out a recap of the 'my_custom_db_id' DB credentials.
#   make db-get-credentials my_custom_db_id
#   # Or :
#   cwt/extensions/db/db/get_credentials.sh my_custom_db_id
#
#   # All locally defined databases at once.
#   make db-get-credentials '%'
#   # Or :
#   cwt/extensions/db/db/get_credentials.sh '%'
#

. cwt/bootstrap.sh

db_ids=()

if [[ "$1" == '%' ]]; then
  u_db_get_ids
elif [[ -n "$1" ]]; then
  db_ids+=("$1")
else
  db_ids+=('default')
fi

u_db_vars_list
echo

for db_id in "${db_ids[@]}"; do
  u_db_set $db_id

  for v in $db_vars_list; do
    var_name="DB_$v"
    echo "$var_name = '${!var_name}'"
  done

  if [[ -n "$dc_db_service_name" ]]; then
    echo "docker-compose service name = '$dc_db_service_name'"
  fi

  echo
done
