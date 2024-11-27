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
# echo "DRUSH DB Driver : Test if database '${p_db_name}' exists (user=$DB_USER, password="$DB_PASS", host="$DB_HOST", port="$DB_PORT")..."

fallback_hook_implementation="cwt/extensions/${DRUSH_DB_DRIVER_FALLBACK}/db/exists.${DRUSH_DB_DRIVER_FALLBACK}.hook.sh"

if u_cwt_extension_exists "$DRUSH_DB_DRIVER_FALLBACK"; then
  echo "Drush DB Driver fallback for 'exists' action :"
  echo "  OK, the '$DRUSH_DB_DRIVER_FALLBACK' extension exists and is enabled."
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
