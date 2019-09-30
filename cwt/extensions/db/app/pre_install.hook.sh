#!/usr/bin/env bash

##
# Implements hook -s 'app' -p 'pre' -a 'install' -v 'PROVISION_USING INSTANCE_TYPE'
#
# Attempts to create local database if it does not exist yet before app install
# hook is triggered.
#
# @see cwt/app/install.sh
# @see cwt/instance/setup.sh
#
# This file is dynamically included when the "hook" is triggered.
#
# Debug lookup paths (make sure this file gets picked up) :
# $ make hook-debug s:app p:pre a:install v:PROVISION_USING INSTANCE_TYPE
#
# @example
#   make app-install
#   # Or :
#   cwt/app/install.sh
#

echo "Making sure DB exists and credentials are properly set ..."

u_db_get_credentials

# TODO [wip] Find better workaround than to wait a few seconds for
# docker-compose stacks. For now, using 5 attempts with 1 second delay before
# considering the test accurate.
case "$PROVISION_USING" in docker-compose)
  if ! u_db_exists "$DB_NAME"; then
    i=0
    max_attempts=5
    while (( i < max_attempts )); do
      i=$(( i+1 ))
      if ! u_db_exists "$DB_NAME"; then
        remaining_attempts=$(( max_attempts-i ))
        sleep 1
      fi
    done
  fi
esac

if u_db_exists "$DB_NAME"; then
  echo "  '$DB_NAME' exists. Carry on."
else
  echo "  '$DB_NAME' does not exist : creating ..."

  if [[ -z "$DB_ADMIN_USER" ]]; then
    read -p "Enter DB admin username (or leave blank to use app user '$DB_USER') : " \
      DB_ADMIN_USER
  fi

  if [[ -z "$DB_ADMIN_PASS" ]]; then
    read -s -p "Enter DB admin password (or leave blank to use the same password as the app user) : " \
      DB_ADMIN_PASS
  fi

  u_db_create

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: failed to create database '$DB_NAME'." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi
fi
