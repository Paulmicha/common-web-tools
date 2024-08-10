#!/usr/bin/env bash

##
# Upload DB dump on remote.
#
# @see scripts/cwt/local/remote-instances/${p_remote_id}.sh
# @see u_remote_instances_setup() in cwt/extensions/remote/remote.inc.sh
#
# @param 1 String : destination remote host ID.
# @param 2 [optional] String : where the DB dump to upload comes from. It can
#   either be a remote host ID, or any subfolder name that will be used to
#   determine where to upload the dump inside the remote dumps base dir.
#   This allows to upload DB dumps previously downloaded locally from other
#   remote instance(s).
#   If we upload DB dumps created in our own local instance, we can use any
#   value, like 'paul'. When this param does not match any remote instance ID,
#   the local dump file selected will be from 'local' and uploaded into a subdir
#   named by this param.
#   Defaults to 'manually-uploaded'.
# @param 3 [optional] String : DB id.
#   Defaults to '', meaning : upload dumps of all DB IDs defined in the remote.
# @param 4 [optional] String : local DB dump file path (relative to the
#   PROJECT_DOCROOT, but absolute paths work too).
#
# @example
#   # Uploads latest DB dump file found in 'local' subfolder to 'dev' remote
#   # inside 'incoming' subfolder :
#   make remote-db-upload 'dev'
#   # Or :
#   cwt/extensions/remote_db/remote/db_upload.sh 'dev'
#
#   # Uploads latest DB dump file found in local 'prod' subfolder to 'dev'
#   # remote inside 'prod' subfolder :
#   make remote-db-upload 'dev' 'prod'
#   # Or :
#   cwt/extensions/remote_db/remote/db_upload.sh 'dev' 'prod'
#
#   # Uploads a specific 'default' DB dump file to the 'staging' remote :
#   make remote-db-upload 'staging' 'local' 'default' data/db-dumps/local/default/2024-08-07-13-45-34_site_foobar.localhost.sql.gz
#   # Or :
#   cwt/extensions/remote_db/remote/db_upload.sh 'staging' 'paul' 'default' data/db-dumps/local/default/2024-08-07-13-45-34_site_foobar.localhost.sql.gz
#

. cwt/bootstrap.sh

remote_id="$1"
remote_subfolder="$2"
db_id="$3"
local_file="$4"

if [[ -z "$remote_id" ]]; then
  echo >&2
  echo "Missing param 1 : remote ID (where to upload the dump)." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

if [[ -z "$remote_subfolder" ]]; then
  remote_subfolder='manually-uploaded'
fi

remote_dir=''
local_subfolder='local'
local_dir=''

# Fallback value for remote_subfolder : it can be a remote instance ID.
# Note that "$remote_subfolder" == "$remote_id" means : upload dumps created on
# that same remote instance (hence, the remote subfolder name will be 'local').
instance_ids=()
u_remote_get_instances

for instance_id in "${instance_ids[@]}"; do
  case "$remote_subfolder" in "$instance_id")
    local_subfolder="$instance_id"
    remote_subfolder="$instance_id"

    if [[ "$remote_subfolder" == "$remote_id" ]]; then
      remote_subfolder='local'
    fi
  esac
done

echo "Uploading DB dump(s) to remote instance $remote_id in $remote_subfolder ..."

declare -A dumps_dict

# When we only read the 'base_dir' from definitions, we get exactly 1 key per
# DB ID (and if we don't specify a DB ID, we get the base dirs of all DB defined
# on that remote by default).
u_remote_db_read_definition "$remote_id" "$db_id" 'base_dir'

for key in "${!dumps_dict[@]}"; do
  db_id="${key%.base_dir}"

  # Debug.
  # echo "$key = '${dumps_dict[$key]}'"
  # echo "db_id = $db_id"

  local_dir="$CWT_DB_DUMPS_BASE_PATH/$local_subfolder/$db_id"

  # Can't carry on if we have no file to upload.
  if [[ -z "$local_file" && ! -d "$local_dir" ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: local folder '$local_dir' does not exist." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  remote_dir="${dumps_dict[$key]}/$remote_subfolder/$db_id";

  # Get local file path to upload.
  # When no local_file is provided, get most recent dump file in local dir
  # corresponding to the DB ID.
  if [[ -z "$local_file" ]]; then
    local_file="$(u_fs_get_most_recent $local_dir '*.gz')"
  fi

  # Debug.
  echo "local_file = '$local_file'"

  if [[ ! -f "$local_file" ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: local file $local_file not found." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi

  # Feedback.
  u_fs_relative_path "$local_file"
  echo "  will upload '$relative_path' to remote dir '$remote_dir' ..."

  # Make sure remote dir exists.
  u_remote_exec_wrapper "$remote_id" \
    "mkdir -p $remote_dir"

  u_remote_upload "$remote_id" \
    "$local_file" \
    "$remote_dir/" \
    --ignore-existing
done

echo "Uploading DB dump(s) to remote instance $remote_id in $remote_subfolder : done."
echo
