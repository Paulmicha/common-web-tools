#!/usr/bin/env bash

##
# Sends local instance DB dump to given remote.
#
# Optionally creates a new dump before sending it over, or uses most recent
# local instance DB dump (default). Always wipes out and restores the dump on
# remote DB.
#
# @param 1 String : the remote id.
# @param 2 [optional] String : path to dump file override or 'new' to create one.
#
# @example
#   make db-sync-to my_remote_id
#   make db-sync-to my_remote_id new
#   make db-sync-to my_remote_id path/to/local/dump/file.sql.tgz
#   # Or :
#   cwt/extensions/remote/db/sync_to.sh my_remote_id
#   cwt/extensions/remote/db/sync_to.sh my_remote_id new
#   cwt/extensions/remote/db/sync_to.sh my_remote_id path/to/local/dump/file.sql.tgz
#

. cwt/bootstrap.sh
u_remote_sync_db_to $@
