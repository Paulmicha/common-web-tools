#!/usr/bin/env bash

##
# Download DB dump(s) from remote.
#
# @see cwt/extensions/remote_db/remote/db_dump.sh
# @see scripts/cwt/local/remote-instances/${p_remote_id}.sh
# @see u_remote_instances_setup() in cwt/extensions/remote/remote.inc.sh
#
# @param 1 [optional] String : remote host ID. This is the root key defined in
#   YAML remote instances definition file : @see remote_instances.local.yml
#   Defaults to 'prod'.
# @param 2 [optional] String : remote DB id.
#   Defaults to '*', meaning : download all DB IDs defined in the remote.
# @param 3 [optional] String : datestamp of the DB dump(s) to download.
#   Defaults to the latest dump (requires the symlink).
#
# @example
#   # Fetch most recent remote DB dump from all DB IDs on remote 'prod' :
#   make remote-db-download 'prod'
#   # Or :
#   cwt/extensions/remote_db/remote/db_download.sh 'prod'
#
#   # Fetch specifically the remote DB dump corresponding to a datestamp :
#   make remote-db-download 'prod' '*' '2024-07-26.00-38-08'
#   # Or :
#   cwt/extensions/remote_db/remote/db_download.sh 'prod' '*' '2024-07-26.00-38-08'
#
#   # Fetch specifically the remote DB dump corresponding to a datestamp from a
#   # single DB ID on remote instance 'prod' :
#   make remote-db-download 'prod' 'api' '2024-07-26.00-38-08'
#   # Or :
#   cwt/extensions/remote_db/remote/db_download.sh 'prod' 'api' '2024-07-26.00-38-08'
#

. cwt/bootstrap.sh

remote_id="$1"
db_id="$2"
datestamp="$3"

if [[ -z "$remote_id" ]]; then
  remote_id='prod'
fi

echo "Downloading DB dumps from remote instance '$remote_id' ..."

declare -A dumps_dict

u_remote_db_prepare_downloads "$remote_id" "$db_id" "$datestamp"

db_id=''
db_ids=()
cmds=()

u_db_get_ids

for db_id in "${db_ids[@]}"; do
  if [[ -z "${dumps_dict["${db_id}.remote_dump_file_path"]}" ]] \
    || [[ -z "${dumps_dict["${db_id}.local_dump_dir"]}" ]]
  then
    continue
  fi

  # Debug.
  # echo "remote_dump_dir = ${dumps_dict["${db_id}.remote_dump_dir"]}"
  # echo "local_dump_dir = ${dumps_dict["${db_id}.local_dump_dir"]}"
  # echo "remote_dump_file_path = ${dumps_dict["${db_id}.remote_dump_file_path"]}"
  # echo "local_dump_file_path = ${dumps_dict["${db_id}.local_dump_file_path"]}"

  # TODO What do we want to do with existing local files ?
  # The use of symlinks always results in the same file name here...
  # if [[ -f "${dumps_dict[${db_id}.local_dump_file_path]}" ]]; then
  #   echo "File already exists."
  # fi

  # Make sure the local dir exists.
  mkdir -p "${dumps_dict["${db_id}.local_dump_dir"]}"

  # Debug.
  # echo "u_remote_download $remote_id ${dumps_dict["${db_id}.remote_dump_file_path"]} ${dumps_dict["${db_id}.local_dump_dir"]}/"

  u_remote_download "$remote_id" \
    "${dumps_dict[${db_id}.remote_dump_file_path]}" \
    "${dumps_dict[${db_id}.local_dump_dir]}/"

  if [[ ! -f "${dumps_dict[${db_id}.local_dump_file_path]}" ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: failed to fetch remote dump file." >&2
    echo >&2
    exit 1
  fi
done

echo "Downloading DB dumps from remote instance '$remote_id' : done."
echo
