#!/usr/bin/env bash

##
# Implements u_hook_most_specific -s 'db' -a 'destroy' -v 'DB_DRIVER HOST_TYPE INSTANCE_TYPE'.
#
# This file is dynamically included when the "hook" is triggered.
# @see u_db_destroy() in cwt/extensions/db/db.inc.sh
#
# The following variables are available here :
#   - DB_ID - defaults to 'default'.
#   - DB_DRIVER - defaults to 'mysql'.
#   - DB_HOST - defaults to 'localhost'.
#   - DB_PORT - defaults to '3306' or '5432' if DB_DRIVER is 'pgsql'.
#   - DB_NAME - defaults to "*".
#   - DB_USER - defaults to first 16 characters of DB_ID.
#   - DB_PASS - defaults to 14 random characters.
#   - DB_ADMIN_USER - defaults to DB_USER.
#   - DB_ADMIN_PASS - defaults to DB_PASS.
#   - DB_TABLES_SKIP_DATA - defaults to an empty string.
# @see u_db_set() in cwt/extensions/db/db.inc.sh
#
# @example
#   make db-destroy
#   # Or :
#   cwt/extensions/db/db/destroy.sh
#

fallback_hook_implementation="cwt/extensions/${DRUSH_DB_DRIVER_FALLBACK}/db/destroy.${DRUSH_DB_DRIVER_FALLBACK}.hook.sh"

if u_cwt_extension_exists "$DRUSH_DB_DRIVER_FALLBACK"; then
  echo "Ok, the '$DRUSH_DB_DRIVER_FALLBACK' extension exists and is enabled."
else
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: the '$DRUSH_DB_DRIVER_FALLBACK' extension appears to be missing or is not enabled." >&2
  echo "It needs to be enabled first." >&2
  echo "@see scripts/cwt/override/.cwt_extensions_ignore" >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

if [[ ! -f "$fallback_hook_implementation" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: the fallback hook implementation appears to be missing." >&2
  echo "Make sure the extension is enabled." >&2
  echo "@see $fallback_hook_implementation" >&2
  echo "@see scripts/cwt/override/.cwt_extensions_ignore" >&2
  echo "-> Aborting (2)." >&2
  echo >&2
  exit 2
fi

. "$fallback_hook_implementation"
