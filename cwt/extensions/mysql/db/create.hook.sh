#!/usr/bin/env bash

##
# Implements hook -s 'db' -a 'create'.
#
# This file is dynamically included when the "hook" is triggered.
# @see u_db_create() in cwt/extensions/db/db.inc.sh
#

echo "Creating database '$DB_NAME' ..."

# TODO [wip] handle DB_ADMIN_USERNAME + DB_ADMIN_PASSWORD separately from base
# extension ?
# @see u_db_get_credentials() in cwt/extensions/db/db.inc.sh

echo "CREATE DATABASE IF NOT EXISTS $DB_NAME;
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USERNAME'@'localhost' IDENTIFIED BY '$DB_PASSWORD';" \
  | mysql \
    --user="$DB_ADMIN_USERNAME" \
    --password="$DB_ADMIN_PASSWORD" \
    --host="$DB_HOST" \
    --port="$DB_PORT"

echo "Creating database '$DB_NAME' : done."
