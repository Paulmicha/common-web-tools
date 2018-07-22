#!/usr/bin/env bash

##
# Implements u_hook_most_specific -s 'db' -a 'backup' -v 'PROVISION_USING'
#
# This file is dynamically included when the "hook" is triggered.
# @see u_db_backup() in cwt/extensions/db/db.inc.sh
#
# @example
#   make db-backup
#   # Or :
#   cwt/extensions/db/db/backup.sh
#

# Prereq check :
# The output path (resulting file) "$db_dump_file" MUST be defined.
if [[ -z "$db_dump_file" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: the output path (resulting file) is not defined." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

mysqldump \
  --user="$DB_USERNAME" \
  --password="$DB_PASSWORD" \
  --host="$DB_HOST" \
  --port="$DB_PORT" \
  "$DB_NAME" > "$db_dump_file"

if [[ $? -ne 0 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: unable to backup DB '$DB_NAME' to dump file '$db_dump_file'." >&2
  echo "-> Aborting (2)." >&2
  echo >&2
  exit 2
fi
