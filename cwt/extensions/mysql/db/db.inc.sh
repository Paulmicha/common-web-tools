#!/usr/bin/env bash

##
# Database-related utility functions.
#
# This file is dynamically loaded.
# @see cwt/bootstrap.sh
#

##
# Gets DB credentials.
#
# @requires global INSTANCE_DOMAIN in calling scope.
#
# @exports DB_ID : underscore-separated string to identify the database, also
#   used "as is" for the DB name, username and password by default.
#   TODO allow alteration (add more params).
# @exports DB_NAME : $DB_ID.
# @exports DB_USERNAME : $DB_ID (truncated to satisfy the 16 characters limit).
# @exports DB_PASSWORD : a random string generated once per instance + DB_ID.
#
# @param 1 [optional] String : unique identifier for requested DB (defaults to
#   INSTANCE_DOMAIN global).
#
u_db_get_credentials() {
  local p_id="$1"

  if [[ -z "$p_id" ]]; then
    p_id="$INSTANCE_DOMAIN";
  fi

  echo "Get (or generate ONCE on current host) the DB credentials for this instance (using ID: $p_id) ..."

  # Note : assumes every instance has a distinct domain, even "local dev" ones.
  export DB_ID=$(u_slugify_u "$p_id")

  export DB_NAME="$DB_ID"
  export DB_USERNAME="$DB_ID"
  export DB_PASSWORD="$(cwt/instance/registry_get.sh "DB_${DB_ID}_PASSWORD")"

  # Generate random local instance DB password and store it for subsequent calls.
  if [[ -z "$DB_PASSWORD" ]]; then
    echo ""
    echo "Generating random local instance DB password..."
    echo ""

    DB_PASSWORD=`< /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo`

    cwt/instance/registry_set.sh "DB_${DB_ID}_PASSWORD" "$DB_PASSWORD"
  fi

  # Prevent MySQL error :
  # ERROR 1470 (HY000) String is too long for user name (should be no longer than 16).
  DB_USERNAME="${DB_USERNAME:0:16}"
}

##
# Restores a dump file into given database.
#
# TODO [wip] implement as scripts (includes) instead of function.
#
# @requires the following globals in calling scope :
# - DB_NAME
# - DB_USERNAME
# - DB_PASSWORD
#
# @param 1 String dump file path.
#
u_db_restore() {
  p_dump_file_path="$1"
  u_db_clear
  u_db_import "$p_dump_file_path"
}

##
# Imports a dump file into given database.
#
# TODO [wip] implement as scripts (includes) instead of function.
#
# @requires the following globals in calling scope :
# - DB_NAME
# - DB_USERNAME
# - DB_PASSWORD
#
# @param 1 String dump file path.
#
u_db_import() {
  p_dump_file_path="$1"

  echo "Importing dump $DUMP_FILE into $DB_NAME DB ..."

  mysql -h localhost -u$DB_USERNAME -p$DB_PASSWORD --default_character_set=utf8 $DB_NAME < $p_dump_file_path

  echo "Importing dump $DUMP_FILE into $DB_NAME DB : over."
  echo
}

##
# Clears given database.
#
# TODO [wip] implement as scripts (includes) instead of function.
#
# @requires the following globals in calling scope :
# - DB_NAME
# - DB_USERNAME
# - DB_PASSWORD
#
u_db_clear() {
  echo "Clearing $DB_NAME DB ..."

  mysqldump -u$DB_USERNAME -p$DB_PASSWORD --add-drop-table --no-data $DB_NAME | grep ^DROP | mysql -u$DB_USERNAME -p$DB_PASSWORD $DB_NAME

  echo "Clearing $DB_NAME DB : over."
  echo
}
