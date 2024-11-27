#!/usr/bin/env bash

##
# Implements hook -s 'app' -a 'install' -v 'PROVISION_USING INSTANCE_TYPE'
#
# Setup new databases (create if it doesn't exist) + import initial dump.
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
    echo "Importing initial DB dump for $db_id DB ..."

    u_db_setup "$db_id"

    echo "Importing initial DB dump for $db_id DB : done."
    echo
  done
esac
