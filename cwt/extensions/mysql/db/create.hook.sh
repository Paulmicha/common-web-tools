#!/usr/bin/env bash

##
# Implements u_hook_most_specific -s 'db' -a 'create' -v 'PROVISION_USING'.
#
# This file is dynamically included when the "hook" is triggered.
# @see u_db_create() in cwt/extensions/db/db.inc.sh
#
# @example
#   make db-create
#   # Or :
#   cwt/extensions/db/db/create.sh
#

echo "Creating database '$DB_NAME' ..."

echo "CREATE DATABASE IF NOT EXISTS $DB_NAME;
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USERNAME'@'$DB_HOST' IDENTIFIED BY '$DB_PASSWORD';" \
  | mysql \
    --user="$DB_ADMIN_USERNAME" \
    --password="$DB_ADMIN_PASSWORD" \
    --host="$DB_HOST" \
    --port="$DB_PORT"

echo "Creating database '$DB_NAME' : done."
