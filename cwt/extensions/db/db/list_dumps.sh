#!/usr/bin/env bash

##
# List local instance DB dump files.
#
# For listing remote DB dumps,
# @see cwt/extensions/remote_db/remote/db_list_dumps.sh
#
# @param 1 [optional] String : the subfolder in the DB dumps dir.
#   Defaults to an empty string, meaning : all subfolders will be listed.
# @param 2 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to an empty string, meaning : list dumps of all defined DB IDs.
#
# @example
#   make db-list-dumps
#   # Or :
#   cwt/extensions/db/db/list_dumps.sh
#

. cwt/bootstrap.sh

p_subdir="$1"
p_db_id="$2"

if [[ -z "$CWT_DB_DUMPS_BASE_PATH" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: the required global 'CWT_DB_DUMPS_BASE_PATH' is undefined." >&2
  echo "Current instance must be (re)initialized with the 'db' extension enabled." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

subdir=''
db_ids=()

u_db_get_ids
u_fs_dir_list "$CWT_DB_DUMPS_BASE_PATH"

echo "Listing dumps in :"

for subdir in $dir_list; do
  if [[ -n "$p_subdir" ]]; then
    case "$subdir" in
      "$p_subdir")
        echo "  $subdir :"
        ;;
      *)
        continue
        ;;
    esac
  else
    echo "  $subdir :"
  fi

  for db_id in "${db_ids[@]}"; do
    dir="$CWT_DB_DUMPS_BASE_PATH/$subdir/$db_id"

    u_fs_relative_path "$dir"

    if [[ -n "$p_db_id" ]]; then
      case "$db_id" in
        "$p_db_id")
          echo "    $db_id ($relative_path) :"
          ;;
        *)
          continue
          ;;
      esac
    else
      echo "    $db_id ($relative_path) :"
    fi

    file_list_arr=()
    u_fs_file_list "$dir"

    for file in "${file_list_arr[@]}"; do
      echo "      $file"
    done
  done
done
