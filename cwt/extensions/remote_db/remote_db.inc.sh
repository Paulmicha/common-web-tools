#!/usr/bin/env bash

##
# Contains DB-related remote utilities.
#
# Complements the 'db' extension (if enabled).
# @see cwt/extensions/db
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Sends local instance DB dump to given remote.
#
# Optionally creates a new dump before sending it over, or uses most recent
# local instance DB dump (default). Always wipes out and restores the dump on
# remote DB.
#
# @param 1 String : the remote id.
# @param 2 [optional] String : path to dump file override or 'new' to create one.
# @param 3 [optional] String : unique DB identifier. Defaults to 'default'.
# @param 4 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#
# @examples
#   # Using the default database :
#   u_remote_sync_db_to my_remote_id
#   u_remote_sync_db_to my_remote_id new
#   u_remote_sync_db_to my_remote_id path/to/local/dump/file.sql.tgz
#
#   # Specifying the database (by DB_ID) :
#   u_remote_sync_db_to my_remote_id '' my_db_id
#   u_remote_sync_db_to my_remote_id new my_db_id
#   u_remote_sync_db_to my_remote_id path/to/local/dump/file.sql.tgz my_db_id
#
u_remote_sync_db_to() {
  local p_id="$1"
  local p_option="$2"

  local rst_dump_file
  local rst_dump_file_relative_path
  local rst_dump_local_base_path
  local rst_dump_remote_base_path
  local rst_leaf
  local rst_dump_dir_on_remote
  local rst_dump_file_on_remote

  u_remote_instance_load "$p_id"

  if [[ -z "$REMOTE_INSTANCE_CONNECT_CMD" ]]; then
    echo >&2
    echo "Error in u_remote_sync_db_to() - $BASH_SOURCE line $LINENO: no conf found for remote id '$p_id'." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  u_db_set "$3" "$4"

  # Handle variants given 1st argument.
  if [[ -n "$p_option" ]]; then
    if [[ -f "$p_option" ]]; then
      rst_dump_file="$p_option"
    else
      case "$p_option" in new)
        u_db_routine_backup
        rst_dump_file="$routine_dump_file"
      esac
    fi
  else
    rst_dump_file="$(u_fs_get_most_recent $CWT_DB_DUMPS_BASE_PATH)"
  fi

  if [[ ! -f "$rst_dump_file" ]]; then
    echo >&2
    echo "Error in u_remote_sync_db_to() - $BASH_SOURCE line $LINENO: no dump file to send." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    return 2
  fi

  # The dump file path on the remote will be placed inside an 'incoming-sync'
  # subfolder in order to avoid collisions risks while limiting fragmentation.

  # 1. Get the dump file relative path.
  relative_path=''
  u_fs_relative_path "$rst_dump_file"
  rst_dump_file_relative_path="$relative_path"

  # 2. Transform its path for use on the remote.
  relative_path=''
  u_fs_relative_path "$CWT_DB_DUMPS_BASE_PATH"
  rst_dump_local_base_path="$relative_path/local/$DB_ID"
  rst_dump_remote_base_path="$relative_path/incoming-sync/$DB_ID"
  rst_dump_file_on_remote="${rst_dump_file_relative_path//$rst_dump_local_base_path/$rst_dump_remote_base_path}"

  # 3. Create the containing folder on the remote (if it doesn't exist yet).
  rst_leaf="${rst_dump_file##*/}"
  rst_dir_on_remote="${rst_dump_file_on_remote%/$rst_leaf}"
  echo "Ensure dir '$rst_dir_on_remote' exists on remote '$p_id' ..."
  u_remote_exec_wrapper "$p_id" \
    mkdir -p "$rst_dir_on_remote"
  echo "Ensure dir '$rst_dir_on_remote' exists on remote '$p_id' : done."

  # 4. Send the file.
  echo "Sending dump file '$rst_dump_file_relative_path' to remote '$p_id' ..."
  u_remote_upload "$p_id" "$rst_dump_file_relative_path" "$rst_dump_file_on_remote"
  echo "Sending dump file '$rst_dump_file_relative_path' to remote '$p_id' : done."

  # 5. Restore it on the remote.
  echo "Restoring '$rst_dump_file_on_remote' on remote '$p_id' ..."
  u_remote_exec_wrapper "$p_id" \
    make db-restore "$rst_dump_file_on_remote"
  echo "Restoring '$rst_dump_file_on_remote' on remote '$p_id' : done."
  echo
}

##
# Fetches DB dump from given remote and restores it locally.
#
# Optionally creates a new dump before fetching it, or uses most recent
# remote instance DB dump (default). Always wipes out and restores the dump on
# local DB.
#
# @param 1 String : the remote id.
# @param 2 [optional] String : path to dump file override or 'new' to create one.
# @param 3 [optional] String : unique DB identifier. Defaults to 'default'.
# @param 4 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#
# @examples
#   # Using the default database :
#   u_remote_sync_db_from my_remote_id
#   u_remote_sync_db_from my_remote_id new
#   u_remote_sync_db_from my_remote_id path/to/remote/dump/file.sql.tgz
#
#   # Specifying the database by DB_ID (e.g. 'my_db_id') :
#   u_remote_sync_db_from my_remote_id '' my_db_id
#   u_remote_sync_db_from my_remote_id new my_db_id
#   u_remote_sync_db_from my_remote_id path/to/remote/dump/file.sql.tgz my_db_id
#
u_remote_sync_db_from() {
  local p_id="$1"
  local p_option="$2"

  local rsf_remote_dump_file
  local rsf_dump_local_base_path
  local rsf_dump_remote_base_path
  local rsf_leaf
  local rsf_local_dump_file

  u_remote_instance_load "$p_id"

  if [[ -z "$REMOTE_INSTANCE_CONNECT_CMD" ]]; then
    echo >&2
    echo "Error in u_remote_sync_db_from() - $BASH_SOURCE line $LINENO: no conf found for remote id '$p_id'." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  u_db_set "$3" "$4"

  # Handle variants given 1st argument.
  if [[ -n "$p_option" ]]; then
    # No check if file exists on the remote instance (perf).
    rsf_remote_dump_file="$p_option"
    case "$p_option" in new)
      rsf_remote_dump_file="$(cwt/extensions/remote/remote/exec.sh "$p_id" "cwt/extensions/db/db/get_dump.sh new")"
      rsf_remote_dump_file="${rsf_remote_dump_file#$REMOTE_INSTANCE_PROJECT_DOCROOT/}"
    esac
  else
    rsf_remote_dump_file="$(cwt/extensions/remote/remote/exec.sh "$p_id" "cwt/extensions/db/db/get_dump.sh")"
    rsf_remote_dump_file="${rsf_remote_dump_file#$REMOTE_INSTANCE_PROJECT_DOCROOT/}"
  fi

  # The local dump file path must be placed inside a subfolder named
  # after the remote instance id in order to avoid any risks of collision.
  rsf_leaf="${rsf_remote_dump_file##*/}"
  rsf_dump_local_base_path="$CWT_DB_DUMPS_BASE_PATH/$p_id/$DB_ID"
  rsf_dump_remote_base_path="$CWT_DB_DUMPS_BASE_PATH/local/$DB_ID"
  rsf_local_dump_file="${rsf_remote_dump_file//$rsf_dump_remote_base_path/$rsf_dump_local_base_path}"

  echo "Fetching dump file '$rsf_remote_dump_file' from remote '$p_id' ..."
  u_remote_download "$p_id" "$rsf_remote_dump_file" "$rsf_local_dump_file"

  if [[ ! -f "$rsf_local_dump_file" ]]; then
    echo >&2
    echo "Error in u_remote_sync_db_from() - $BASH_SOURCE line $LINENO: failed to fetch remote dump file." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    return 2
  else
    echo "Fetching dump file '$rsf_remote_dump_file' from remote '$p_id' : done."
  fi

  echo "Restoring it locally ..."
  u_db_restore "$rsf_local_dump_file"
  echo "Restoring it locally : done."
  echo
}
