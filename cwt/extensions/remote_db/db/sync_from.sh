#!/usr/bin/env bash

##
# Fetches DB dump from given remote and restores it locally.
#
# Optionally creates a new dump before fetching it, or uses most recent
# remote instance DB dump (default). Always wipes out and restores the dump on
# local DB.
#
# @param 1 String : the remote id.
# @param 2 [optional] String : path to dump file override or 'new' to create one.
#
# @example
#   make db-sync-from my_remote_id
#   make db-sync-from my_remote_id new
#   make db-sync-from my_remote_id path/to/remote/dump/file.sql.tgz
#   # Or :
#   cwt/extensions/remote/db/sync_from.sh my_remote_id
#   cwt/extensions/remote/db/sync_from.sh my_remote_id new
#   cwt/extensions/remote/db/sync_from.sh my_remote_id path/to/remote/dump/file.sql.tgz
#

. cwt/bootstrap.sh
u_remote_sync_db_from $@
