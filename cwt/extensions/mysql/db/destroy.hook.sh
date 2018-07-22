#!/usr/bin/env bash

##
# Implements u_hook_most_specific -s 'db' -a 'destroy' -v 'PROVISION_USING'.
#
# This file is dynamically included when the "hook" is triggered.
# @see u_db_destroy() in cwt/extensions/db/db.inc.sh
#
# @example
#   make db-destroy
#   # Or :
#   cwt/extensions/db/db/destroy.sh
#

echo "Destroying database '$DB_NAME' ..."

echo "DROP DATABASE $DB_NAME;" \
  | mysql \
    --user="$DB_ADMIN_USERNAME" \
    --password="$DB_ADMIN_PASSWORD" \
    --host="$DB_HOST" \
    --port="$DB_PORT"

echo "Destroying database '$DB_NAME' : done."
