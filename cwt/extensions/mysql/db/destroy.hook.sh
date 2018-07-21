#!/usr/bin/env bash

##
# Implements hook -s 'db' -a 'destroy'.
#
# This file is dynamically included when the "hook" is triggered.
# @see u_db_destroy() in cwt/extensions/db/db.inc.sh
#

echo "Destroying database '$DB_NAME' ..."

# TODO [wip] handle DB_ADMIN_USERNAME + DB_ADMIN_PASSWORD separately from base
# extension ?
# @see u_db_get_credentials() in cwt/extensions/db/db.inc.sh

echo "DROP DATABASE $DB_NAME;" \
  | mysql \
    --user="$DB_ADMIN_USERNAME" \
    --password="$DB_ADMIN_PASSWORD" \
    --host="$DB_HOST" \
    --port="$DB_PORT"

echo "Destroying database '$DB_NAME' : done."
