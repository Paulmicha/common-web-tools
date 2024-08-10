#!/usr/bin/env bash

##
# Remotely create DB dump.
#
# @param 1 [optional] String : remote host ID. This is the root key defined in
#   YAML remote instances definition file : @see remote_instances.local.yml
#   Defaults to 'prod'.
# @param 2 [optional] String : remote DB id.
#   Defaults to '', meaning : all DB IDs defined in the remote.
#
# @example
#   # On 'prod' remote by default : all DB IDs defined in 'prod' are dumped.
#   make remote-db-dump
#   # Or :
#   cwt/extensions/remote_db/remote/db_dump.sh
#
#   # Same, but on 'preprod' remote :
#   make remote-db-dump 'preprod'
#   # Or :
#   cwt/extensions/remote_db/remote/db_dump.sh 'preprod'
#
#   # Only specific DB ID(s) :
#   make remote-db-dump 'prod' 'default'
#   make remote-db-dump 'dev' 'api'
#   # Or :
#   cwt/extensions/remote_db/remote/db_dump.sh 'prod' 'default'
#   cwt/extensions/remote_db/remote/db_dump.sh 'dev' 'api'
#

. cwt/bootstrap.sh

remote_id="$1"
db_id="$2"

declare -A dumps_dict

if [[ -z "$remote_id" ]]; then
  remote_id='prod'
fi

echo "Creating DB dumps on remote instance '$remote_id' ..."

u_remote_instance_load "$remote_id"
u_remote_db_prepare_dumps "$remote_id" "$db_id"

# We no longer require the argument "$2" from here, so it's fine to reuse this
# var name.
db_id=''

db_ids=()
cmds=()

u_db_get_ids

for db_id in "${db_ids[@]}"; do
  # Debug.
  # echo "${db_id}.cmd = ${dumps_dict["${db_id}.cmd"]}"
  # echo "${db_id}.file = ${dumps_dict["${db_id}.file"]}"
  # echo "${db_id}.base_dir = ${dumps_dict["${db_id}.base_dir"]}"
  # echo "${db_id}.dir = ${dumps_dict["${db_id}.dir"]}"
  # echo "${db_id}.type = ${dumps_dict["${db_id}.type"]}"
  # echo
  # continue

  # We need at least the 'cmd' and 'dir' parts to remotely create the dump.
  if [[ -z "${dumps_dict["${db_id}.cmd"]}" ]] \
    || [[ -z "${dumps_dict["${db_id}.dir"]}" ]]
  then
    continue
  fi

  # Create the destination dir (if it does not exist yet).
  cmds+=("mkdir -p '${dumps_dict["${db_id}.dir"]}'")

  # Then run the dump.
  cmds+=("${dumps_dict["${db_id}.cmd"]}")

  # Allow other implementations to react to or alter the remote execution.
  db_type='mysql'

  if [[ -n "${dumps_dict["${db_id}.type"]}" ]]; then
    db_type="${dumps_dict["${db_id}.type"]}"
  fi

  # If requested, create or update the symlink to point to the latest dump.
  if [[ -n "${dumps_dict[${db_id}.latest_symlink]}" ]]; then
    cmds+=("ln -sf ${dumps_dict[${db_id}.dir]}/${dumps_dict[${db_id}.file]}.gz ${dumps_dict[${db_id}.dir]}/${dumps_dict[${db_id}.latest_symlink]}.gz")
  fi

  # E.g. implement dumps rotation, commands substitutions per remote, etc.
  hook -s 'remote_db' -a 'dump' -v 'db_type db_id remote_id'
done

# Finally, execute all commands remotely (string initialized with item 0 + start
# the loop below at item 1 to handle joining commands with '&&' ; makes the
# remote exec abort on any error at any step).
joined_str="${cmds[0]}"

for cmd in "${cmds[@]:1}"; do
  joined_str+=" && $cmd"
done

# Debug.
# echo "$joined_str"

if [[ -n "$joined_str" ]]; then
  u_remote_exec_wrapper "$remote_id" $joined_str
fi

echo "Creating DB dumps on remote instance '$remote_id' : done."
echo
