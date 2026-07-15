#!/usr/bin/env bash

##
# In order to convert "real" local DB dumps path to container bind mount volumes
# paths, we need the "in container" base path.
#
# @example
#   @see cwt/extensions/drush/db/exec.drush.compose.hook.sh
#

# TODO document the dir used by default. It is meant to be bind mounted, e.g. :
# volumes:
#   - ./$CWT_DB_DUMPS_DIR:$CWT_DB_DUMPS_DIR_C
global CWT_DB_DUMPS_DIR_C "[default]=/cwt/data/db-dumps [help]='Same as CWT_DB_DUMPS_DIR but within containers.'"

for db_id in $CWT_DB_IDS; do
  u_str_uppercase "$db_id" 'DB_ID'

  global "${DB_ID}_DB_DUMPS_LOCAL_DIR_C" "[default]='${CWT_DB_DUMPS_DIR_C}/$db_id/local' [help]='Same as ${DB_ID}_DB_DUMPS_LOCAL_DIR_C but within containers.'"
done
