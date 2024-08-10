#!/usr/bin/env bash

##
# Implements hook -s 'app' -a 'install' -v 'PROVISION_USING INSTANCE_TYPE'
#
# Restores any dump matching every defined DB ID. The dump file(s) can be in any
# subfolder, as long as they correspond to the corrrect DB ID.
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
    u_db_restore_any "$db_id"
  done
esac
