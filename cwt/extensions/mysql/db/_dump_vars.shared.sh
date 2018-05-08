#!/usr/bin/env bash

##
# Declares common variables used in more than 1 script.
#
# This file is required by the following scripts :
# - cwt/db/backup.docker-compose.hook.sh
# - cwt/db/restore.docker-compose.hook.sh
#
# @requires or uses the following globals in calling scope :
# - DB_DUMP_BASE_PATH
# - DB_DUMP_CONTAINER_BASE_PATH (if "$PROVISION_USING" == "docker-compose*")
# - DB_NAME
# - DB_USERNAME (defaults to DB_NAME)
# - DB_PASSWORD (defaults to DB_NAME)
# - DB_HOST (defaults to localhost)
# - DB_PORT (defaults to 3306)
#

if [[ -z "$DB_NAME" ]]; then
  echo
  echo "Error in $BASH_SOURCE line $LINENO: \$DB_NAME is empty."
  echo "-> aborting (1)."
  echo
  exit 1
fi
if [[ ! -d "$DB_DUMP_BASE_PATH" ]]; then
  echo
  echo "Error in $BASH_SOURCE line $LINENO: \$DB_DUMP_BASE_PATH is not a directory."
  echo "-> aborting (2)."
  echo
  exit 2
fi
if [[ ("$PROVISION_USING" == "docker-compose*") && (-z "$DB_DUMP_CONTAINER_BASE_PATH") ]]; then
  echo
  echo "Error in $BASH_SOURCE line $LINENO: \$DB_DUMP_CONTAINER_BASE_PATH is empty."
  echo "-> aborting (3)."
  echo
  exit 3
fi

if [[ -z "$DB_USERNAME" ]]; then
  DB_USERNAME="$DB_NAME"
fi
if [[ -z "$DB_PASSWORD" ]]; then
  DB_PASSWORD="$DB_NAME"
fi
if [[ -z "$DB_HOST" ]]; then
  DB_HOST='localhost'
fi
if [[ -z "$DB_PORT" ]]; then
  DB_PORT='3306'
fi

# The 'restore' op does not need the $DUMP_DIR by date -> differenciate by using
# an extra var in sourcing scope.
# NB : the following paths are *relative* to DB_DUMP_BASE_PATH (and
# DB_DUMP_CONTAINER_BASE_PATH if applicable).
if [[ "$dump_op" == 'backup' ]]; then
  DUMP_DIR="$(date +%Y)/$(date +%m)/$(date +%d)"
  DUMP_FILE_NAME="$(date +%H)-$(date +%M)-$(date +%S).sql"
  DUMP_FILE="${DUMP_DIR}/${DUMP_FILE_NAME}"
fi

DUMP_FILE_LAST="last.sql"
