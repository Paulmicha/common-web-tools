#!/usr/bin/env bash

##
# Restore DB dump on remote.
#
# By default, this remotely restores a DB dump created on that same instance.
# E.g. it will restore dumps from "$REMOTE_INSTANCE_DUMPS_DEFAULT_BASE_DIR/local",
# which contains dumps (of the 'default' DB) previously created on the same
# remote instance.
#
# @see cwt/extensions/remote_db/remote/db_upload.sh
# @see scripts/cwt/local/remote-instances/${p_remote_id}.sh
# @see u_remote_instances_setup() in cwt/extensions/remote/remote.inc.sh
#
# @param 1 String : destination remote host ID.
# @param 2 [optional] String : where the DB dump to restore comes from. It can
#   either be a remote host ID, or any subfolder name that will be used to
#   determine where is the dump inside the remote dumps base dir.
#   Defaults to 'local'.
# @param 3 [optional] String : DB id.
#   Defaults to '', meaning : upload dumps of all DB IDs defined in the remote.
# @param 4 [optional] String : remote DB dump file path (relative to the
#   REMOTE_INSTANCE_DOCROOT, but absolute paths work too).
#
# @example
#   # Uploads latest DB dump file found in 'local' subfolder to 'dev' remote
#   # inside 'incoming' subfolder :
#   make remote-db-upload 'dev'
#   # Or :
#   cwt/extensions/remote_db/remote/db_restore.sh 'dev'
#
#   # Uploads latest DB dump file found in local 'prod' subfolder to 'dev'
#   # remote inside 'prod' subfolder :
#   make remote-db-upload 'dev' 'prod'
#   # Or :
#   cwt/extensions/remote_db/remote/db_restore.sh 'dev' 'prod'
#

. cwt/bootstrap.sh

remote_id="$1"
remote_subfolder="$2"
db_id="$3"
remote_file="$4"

if [[ -z "$remote_id" ]]; then
  echo >&2
  echo "Missing param 1 : remote ID." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

if [[ -z "$remote_subfolder" ]]; then
  remote_subfolder='local'
fi

# Fallback value for remote_subfolder : it can be a remote instance ID.
# Note that "$from" == "$remote_id" means : restore dumps created on that same
# remote instance (hence, the remote subfolder name will be 'local').
if [[ -n "$from" ]]; then
  instance_ids=()
  u_remote_get_instances

  for instance_id in "${instance_ids[@]}"; do
    case "$from" in "$instance_id")
      if [[ "$remote_subfolder" != "$remote_id" ]]; then
        remote_subfolder="$instance_id"
      fi
    esac
  done
fi

# TODO [wip] datestamp filtering of local DB dump file to upload.
if [[ -n "$datestamp" ]]; then
  echo >&2
  echo "TODO in $BASH_SOURCE line $LINENO: datestamp filtering not done yet." >&2
  echo "-> Aborting." >&2
  echo >&2
  exit 99
fi

echo "Restoring DB dump(s) on remote instance '$remote_id' ..."

remote_dir=''

declare -A dumps_dict

# When we only read the 'base_dir' from definitions, we get exactly 1 key per
# DB ID (and if we don't specify a DB ID, we get the base dirs of all DB defined
# on that remote by default).
u_remote_db_read_definition "$remote_id" "$db_id" 'base_dir'

for key in "${!dumps_dict[@]}"; do
  remote_dir="${dumps_dict[$key]}/$remote_subfolder";

  # TODO [wip]
  remote_file="$(u_remote_exec_wrapper "$remote_id" "find $remote_dir -maxdepth 1 -type f -name '*.gz' -exec ls -1t '{}' + | head -n1")"

  # u_remote_exec_wrapper "$remote_id" \
  #   "if [[ ! -f $remote_file ]] ; then echo 'Error : no dump file found in $remote_dir' >&2 && exit 1 ; else echo 'Ok file $remote_file exists' && exit 0 ; fi"
  # if [[ $? -ne 0 ]]; then
  #   continue
  # fi

  echo "  will restore '$remote_file' from remote dir '$remote_dir' ..."

  # TODO [wip]
  # cmds=()
  # cmds+=("echo 'Uncompress $dump_file.gz ...'")
  # cmds+=("gunzip -c $dump_file_path.gz > $dump_file_path")
  # cmds+=("echo 'Uncompress $dump_file.gz : done.'")

  # cmds+=("echo 'Restore $dump_file ...'")
  # cmds+=("drush --uri='$uri' sql-drop -y")
  # cmds+=("drush --uri='$uri' sql-cli < $dump_file_path")
  # cmds+=("echo 'Restore $dump_file : done.'")

  # cmds+=("echo 'Cleanup uncompressed copy ...'")
  # cmds+=("rm -f $dump_file_path")
  # cmds+=("echo 'Cleanup uncompressed copy : done.'")
done

echo "Restoring DB dump(s) on remote instance '$remote_id' : done."
echo
