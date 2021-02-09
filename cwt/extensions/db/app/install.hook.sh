#!/usr/bin/env bash

##
# Implements hook -s 'app' -a 'install' -v 'PROVISION_USING INSTANCE_TYPE'
#
# If CWT_DB_INITIAL_IMPORT is set to true, the first dump file whose name
# matches « initial.* » found in CWT_DB_DUMPS_BASE_PATH during app install and
# instance setup.
#
# @see cwt/app/install.sh
# @see cwt/instance/setup.sh
#
# This file is dynamically included when the "hook" is triggered.
#
# Debug lookup paths (make sure this file gets picked up) :
# $ make hook-debug s:app a:install v:PROVISION_USING INSTANCE_TYPE
#
# @example
#   make app-install
#   # Or :
#   cwt/app/install.sh
#

case "$CWT_DB_INITIAL_IMPORT" in true)
  db_ids=()
  u_db_get_ids

  for db_id in "${db_ids[@]}"; do
    initial_dump_file="$(u_db_get_dump 'initial' "$db_id")"

    if [[ -f "$initial_dump_file" ]]; then
      echo "Importing initial '$db_id' DB dump file '$initial_dump_file' ..."

      u_db_restore "$initial_dump_file" "$db_id"

      if [[ $? -ne 0 ]]; then
        echo >&2
        echo "Error in $BASH_SOURCE line $LINENO: failed to import initial DB dump file '$initial_dump_file'." >&2
        echo "-> Aborting (1)." >&2
        echo >&2
        exit 1
      fi

      echo "Importing initial '$db_id' DB dump file '$initial_dump_file' : done."
    fi
  done
esac
