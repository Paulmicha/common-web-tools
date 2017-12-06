#!/bin/bash

##
# Gets local instance DB credentials.
#
# This script initializes a random password the first time it is called (but
# not on subsequent calls). It is idempotent.
#
# @requires cwt/bash_utils.sh
# @requires global $INSTANCE_DOMAIN in scope.
#
# Usage :
# $ . cwt/db/get_credentials.sh
#

echo "Get (or generate ONCE on current host) the DB credentials for this instance ..."

# Note : assumes every instance has a distinct domain, even "local dev" ones.
export DB_ID=$(u_slugify_u $INSTANCE_DOMAIN)

export DB_NAME=$DB_ID
export DB_USERNAME=$DB_ID
export DB_PASSWORD=$(u_registry_get_val "DB_${DB_ID}_PASSWORD")

# Generate random local instance DB password and store it for subsequent calls.
if [[ -z "$DB_PASSWORD" ]]; then
  echo ""
  echo "Generating random local instance DB password..."
  echo ""

  DB_PASSWORD=`< /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo`

  u_registry_set_val "DB_${DB_ID}_PASSWORD" $DB_PASSWORD
fi

# Prevent MySQL error :
# ERROR 1470 (HY000) String is too long for user name (should be no longer than 16).
DB_USERNAME=${DB_USERNAME:0:16}
