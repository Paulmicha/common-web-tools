#!/usr/bin/env bash

##
# Gets local instance DB credentials.
#
# @see u_db_get_credentials()
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

. cwt/bootstrap.sh
u_db_get_credentials $@

echo "Details for local database '$DB_ID' :"
echo "  DB_DRIVER = '$DB_DRIVER'"
echo "  DB_HOST = '$DB_HOST'"
echo "  DB_PORT = '$DB_PORT'"
echo "  DB_NAME = '$DB_NAME'"
echo "  DB_USER = '$DB_USER'"
echo "  DB_PASS = '$DB_PASS'"
echo "  DB_ADMIN_USER = '$DB_ADMIN_USER'"
echo "  DB_ADMIN_PASS = '$DB_ADMIN_PASS'"
echo "  DB_TABLES_SKIP_DATA = '$DB_TABLES_SKIP_DATA'"
