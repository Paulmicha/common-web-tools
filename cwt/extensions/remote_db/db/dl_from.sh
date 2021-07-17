#!/usr/bin/env bash

##
# Just fetches DB dump from given remote (without restoring it locally).
#
# Optionally creates a new dump before fetching it, or uses most recent
# remote instance DB dump (default). Always wipes out and restores the dump on
# local DB.
#
# @param 1 String : the remote id.
# @param 2 [optional] String : path to dump file override or 'new' to create one.
#
# @example
#   make db-dl-from my_remote_id
#   make db-dl-from my_remote_id new
#   make db-dl-from my_remote_id path/to/remote/dump/file.sql.tgz
#   # Or :
#   cwt/extensions/remote/db/dl_from.sh my_remote_id
#   cwt/extensions/remote/db/dl_from.sh my_remote_id new
#   cwt/extensions/remote/db/dl_from.sh my_remote_id path/to/remote/dump/file.sql.tgz
#

. cwt/bootstrap.sh
u_remote_download_db_from $@
