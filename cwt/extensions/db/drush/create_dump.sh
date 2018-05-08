#!/usr/bin/env bash

##
# Make local DB dump.
#
# Usage from project root dir :
# $ . cwt/db/drush/create_dump.sh
#

newrev=$(cd web && git log --pretty=format:'%H' -n 1)

DIR=`pwd`
DUMP_DIR="$DIR/dumps/$(date +%Y)/$(date +%m)/$(date +%d)"
DUMP_FILE_NAME="$(date +%H)-$(date +%M)-$(date +%S)-${newrev:0:8}.sql"
DUMP_FILE="${DUMP_DIR}/${DUMP_FILE_NAME}"
DUMP_FILE_LAST="$DIR/dumps/last.sql.gz"

if [ ! -d $DUMP_DIR ]; then
  mkdir -p $DUMP_DIR
fi

drush sql-dump --gzip --result-file=$DUMP_FILE_NAME --structure-tables-list="cache,cache_*,history,search_*,sessions,watchdog"

# Move the file outside the Docker volume.
mv "$DIR/web/$DUMP_FILE_NAME.gz" "$DUMP_FILE.gz"

# Copy over as last dump for quicker restores.
# @see cwt/local/db/restore_last_dump.sh
cp -f "$DUMP_FILE.gz" $DUMP_FILE_LAST
