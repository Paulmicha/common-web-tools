#!/usr/bin/env bash

##
# Implements u_hook_most_specific -s 'db' -a 'ensure_creds' -v 'DB_DRIVER DB_ID INSTANCE_TYPE'.
#
# @requires the following var in calling scope :
# @var db_exists
#
# @see u_db_exists() in cwt/extensions/db/db.inc.sh
#
# @example
#   u_db_ensure_creds
#   u_db_ensure_creds 'custom_db_id'
#

echo "Ensuring $DB_ID $DB_DRIVER database '$DB_NAME' on $DB_HOST has proper grants setup for user $DB_USER ..."

# MySQL 8+ no longer supports IDENTIFIED BY within GRANT.
# DB_HOST is the database server host (where we connect), not the user host part.
# Default to '%' so app containers can connect.
DB_USER_HOST="${DB_USER_HOST:-%}"

# Workaround mysqldump: Error: 'Access denied; you need (at least one of) the
# PROCESS privilege(s) for this operation' when trying to dump tablespaces.
# This error occurs because recent versions of MySQL (5.7.31+ and 8.0.21+)
# require the global PROCESS privilege for mysqldump to access tablespace
# information. If your user only has permissions for a specific database, they
# will lack this global privilege by default.
echo "CREATE USER IF NOT EXISTS '$DB_USER'@'$DB_USER_HOST' IDENTIFIED BY '$DB_PASS';
ALTER USER '$DB_USER'@'$DB_USER_HOST' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'$DB_USER_HOST';
GRANT PROCESS ON *.* TO '$DB_USER'@'$DB_USER_HOST';
FLUSH PRIVILEGES;" \
  | mysql \
    --user="$DB_ADMIN_USER" \
    --password="$DB_ADMIN_PASS" \
    --host="$DB_HOST" \
    --port="$DB_PORT"

echo "Ensuring $DB_ID $DB_DRIVER database '$DB_NAME' on $DB_HOST has proper grants setup for user $DB_USER : done."
