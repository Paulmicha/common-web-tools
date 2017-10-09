#!/bin/bash

##
# Gets local instance DB credentials.
#
# This script initializes a random password the first time it is called (but
# not on subsequent calls). It is idempotent.
#
# Usage :
# $ . scripts/db/get_credentials.sh
#

. scripts/env/load.sh

# Note : assumes every instance has a distinct domain, even "local dev" ones.
DB_ID=$(u_slugify_u $INSTANCE_DOMAIN)

DB_NAME=$DB_ID
DB_USERNAME=$DB_ID
DB_PASSWORD=$(u_registry_get_val "DB_${DB_ID}_PASSWORD")

# Generate random local instance DB password and store it for subsequent calls.
if [[ -z "$DB_PASSWORD" ]]; then
  echo ""
  echo "Generating random local instance DB password..."
  echo ""

  DB_PASSWORD=`< /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo`

  u_registry_set_val "DB_${DB_ID}_PASSWORD" $DB_PASSWORD
fi
