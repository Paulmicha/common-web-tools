#!/usr/bin/env bash

##
# Remotely lists DB dumps.
#
# @param 1 [optional] String : remote host ID. This is the root key defined in
#   YAML remote instances definition file : @see remote_instances.local.yml
#   Defaults to 'prod'.
# @param 2 [optional] String : remote DB id.
#   Defaults to '', meaning : all DB IDs defined in the remote.
# @param 3 [optional] String : subfolder in DB dumps dir.
#   Defaults to 'local', meaning : list DB dumps that were created on the remote
#   instance itself (not uploaded there).
#   This allows to also list the dump files previously uploaded on that remote.
#
# @example
#   # On 'prod' remote by default : all DB IDs defined in 'prod' are dumped.
#   make remote-db-list-dumps
#   # Or :
#   cwt/extensions/remote_db/remote/db_list_dumps.sh
#
#   # Same, but on 'preprod' remote :
#   make remote-db-list-dumps 'preprod'
#   # Or :
#   cwt/extensions/remote_db/remote/db_list_dumps.sh 'preprod'
#
#   # Only specific DB ID(s) :
#   make remote-db-list-dumps 'prod' 'default'
#   make remote-db-list-dumps 'dev' 'api'
#   # Or :
#   cwt/extensions/remote_db/remote/db_list_dumps.sh 'prod' 'default'
#   cwt/extensions/remote_db/remote/db_list_dumps.sh 'dev' 'api'
#

. cwt/bootstrap.sh

remote_id="$1"
db_id="$2"
subfolder="$3"

if [[ -z "$remote_id" ]]; then
  remote_id='prod'
fi

u_remote_check_id "$remote_id"

if [[ -z "$subfolder" ]]; then
  subfolder='local'
fi

declare -A dumps_dict

# When we only read the 'base_dir' from definitions, we get exactly 1 key per
# DB ID (and if we don't specify a DB ID, we get the base dirs of all DB defined
# on that remote by default).
u_remote_db_read_definition "$remote_id" "$db_id" 'base_dir'

for key in "${!dumps_dict[@]}"; do
  db_id="${key%.base_dir}"

  echo "Listing $remote_id dumps ($key) :"
  echo

  u_remote_exec_wrapper "$remote_id" \
    "find ${dumps_dict[$key]}/$subfolder/$db_id -maxdepth 1 -type f -name '*.gz' -exec ls -1t '{}' +"

  echo
done
