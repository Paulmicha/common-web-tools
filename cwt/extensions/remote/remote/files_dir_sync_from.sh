#!/usr/bin/env bash

##
# Manual sync of public or private files dirs (git-ignored assets).
#
# @param 1 [optional] String : remote host ID. This is the root key defined in
#   YAML remote instances definition file : @see remote_instances.local.yml
#   Defaults to 'prod'.
# @param 2 [optional] String : the type of files. This is also defined in
#   YAML remote instances definition file : @see remote_instances.local.yml
#   Defaults to all types of files found in the remote instance definition.
#
# @example
#   # Fetch all types of files from 'prod' remote (public, private).
#   make remote-files-dir-sync-from
#   # Or :
#   cwt/extensions/remote/remote/files_dir_sync_from.sh
#
#   # From the 'preprod' remote :
#   make remote-files-dir-sync-from 'preprod'
#   # Or :
#   cwt/extensions/remote/remote/files_dir_sync_from.sh 'preprod'
#
#   # Only 'public' files :
#   make remote-files-dir-sync-from 'prod' 'public'
#   # Or :
#   cwt/extensions/remote/remote/files_dir_sync_from.sh 'prod' 'public'
#

. cwt/bootstrap.sh

remote_id="$1"
files_type="$2"

if [[ -z "$remote_id" ]]; then
  remote_id='prod'
fi

u_remote_check_id "$remote_id"

echo "Fetching files from '$remote_id' remote ..."

u_remote_instance_load "$remote_id"

for suffix in $CWT_REMOTE_FILES_SUFFIXES; do
  if [[ -n "$files_type" ]]; then
    case "$suffix" in
      "$files_type")
        echo "  $suffix files only ..."
        ;;
      # Skip any non-matching DB ID on given remote.
      *)
        continue
        ;;
    esac
  fi

  u_str_sanitize_var_name "$suffix" 'suffix'
  u_str_uppercase "$suffix" 'SUFFIX'

  var="REMOTE_INSTANCE_FILES_${SUFFIX}_REMOTE"
  remote_dir="${!var}"

  var="REMOTE_INSTANCE_FILES_${SUFFIX}_LOCAL"
  local_dir="${!var}"

  if [[ -z "$remote_dir" ]] || [[ -z "$local_dir" ]]; then
    continue
  fi

  tokens_replaced=''
  u_remote_definition_tokens_replace "$remote_id" "$remote_dir"
  remote_dir="$tokens_replaced"

  tokens_replaced=''
  u_remote_definition_tokens_replace "$remote_id" "$local_dir"
  local_dir="$tokens_replaced"

  # Debug.
  # echo "remote_dir = '$remote_dir'"
  # echo "local_dir = '$local_dir'"
  # echo "rsync -a $REMOTE_INSTANCE_PREFIX:$remote_dir $local_dir/"

  if [[ ! -d "$local_dir" ]]; then
    mkdir -p "$local_dir"
    echo "  (also created missing local dir $local_dir)"
  fi

  rsync -av "$REMOTE_INSTANCE_PREFIX:$remote_dir" "$local_dir/"
done

echo "Fetching files from '$remote_id' remote : done."
