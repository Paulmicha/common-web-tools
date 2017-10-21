#!/bin/bash

##
# Creates the database using initialized env vars.
#
# Usage :
# $ . cwt/db/setup.sh
#

. cwt/env/load.sh

echo "CREATE DATABASE IF NOT EXISTS $DB_NAME;
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USERNAME'@'localhost' IDENTIFIED BY '$DB_PASSWORD';" | mysql -u $DB_ADMIN_USERNAME -p$DB_ADMIN_PASSWORD

echo ""
echo "Over."
echo ""
