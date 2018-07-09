#!/usr/bin/env bash

##
# Basic database utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#

##
# Gets DB credentials (opt-out available when CWT_DB_MODE = 'none').
#
# @requires the following globals in calling scope :
# - INSTANCE_DOMAIN
# - CWT_DB_MODE
# - CWT_DB_DUMPS_BASE_PATH
#
# @exports DB_ID : underscore-separated string to identify the database, also
#   used "as is" for the DB name, username and password by default in 'auto' mode.
# @exports DB_NAME : $DB_ID.
# @exports DB_USERNAME : $DB_ID (truncated to satisfy the 16 characters limit).
# @exports DB_PASSWORD : a random string generated once per instance + DB_ID.
#
# @param 1 [optional] String : unique identifier for requested DB (defaults to
#   sanitized INSTANCE_DOMAIN global).
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#
u_db_get_credentials() {
  if [[ -z "$CWT_DB_DUMPS_BASE_PATH" ]]; then
    echo >&2
    echo "Error in u_db_get_credentials() - $BASH_SOURCE line $LINENO: the required global 'CWT_DB_DUMPS_BASE_PATH' is undefined." >&2
    echo "Current instance must be (re)initialized with the 'db' extension enabled." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  local p_db_id="$1"
  local p_force_reload="$2"
  local reg_val

  # If DB credentials vars are already exported in current shell scope, no need
  # to carry on.
  if [[ -n "$DB_ID" ]] && [[ -z "$p_force_reload" ]]; then
    return
  fi

  if [[ -z "$p_db_id" ]]; then
    # Note : assumes every instance has a distinct domain, even "local dev" ones
    # if cwt/extensions/file_registry is used as registry storage backend.
    if [[ -z "$INSTANCE_DOMAIN" ]]; then
      echo >&2
      echo "Error in u_db_routine_backup() - $BASH_SOURCE line $LINENO: the required global 'INSTANCE_DOMAIN' is undefined." >&2
      echo "-> Aborting (2)." >&2
      echo >&2
      exit 2
    fi
    p_db_id="$INSTANCE_DOMAIN";
  fi

  u_str_sanitize_var_name "$p_db_id" 'p_db_id'
  export DB_ID="$p_db_id"

  case "$CWT_DB_MODE" in
    # Some environments do not require CWT to handle DB credentials at all.
    none)
      return
      ;;

    # The 'auto' mode means we only store the password, which gets generated once
    # on first call (and read otherwise).
    auto)
      export DB_NAME="$DB_ID"
      export DB_USERNAME="$DB_ID"

      # Prevent MySQL ERROR 1470 (HY000) String is too long for user name - should
      # be no longer than 16 characters.
      # Warning : this creates naming collision risks (considered edge case).
      DB_USERNAME="${DB_USERNAME:0:16}"

      # Attempts to load password from registry (secrets store).
      # Warning : if cwt/extensions/file_registry is used as registry storage
      # backend, no encryption will be used. This may be fine for local dev - e.g.
      # in temporary virtual machines inaccessible to the outside world, but
      # it is obviously a security risk.
      reg_val=''
      u_instance_registry_get "${p_db_id}.DB_PASSWORD"

      # Generate random local instance DB password and store it for subsequent
      # calls.
      if [[ -z "$reg_val" ]]; then
        export DB_PASSWORD=`< /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo`
        u_instance_registry_set "${p_db_id}.DB_PASSWORD" "$DB_PASSWORD"
      fi
    ;;

    # 'manual' mode requires terminal (prompts) on first call.
    manual)
      local var
      local val
      local val_default
      local vars_to_getset='DB_NAME DB_USERNAME DB_PASSWORD DB_HOST DB_PORT'

      for var in $vars_to_getset; do
        val=''
        val_default=''
        reg_val=''
        u_instance_registry_get "${p_db_id}.${var}"

        # Value is not found in registry (secrets store)
        # -> init & store.
        if [[ -z "$reg_val" ]]; then
          case "$var" in
            DB_NAME)
              val_default="$DB_ID"
              ;;
            DB_USERNAME)
              val_default="${DB_ID:0:16}"
              ;;
            DB_PASSWORD)
              val_default=`< /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo`
              ;;
            DB_HOST)
              val_default='localhost'
              ;;
            DB_PORT)
              val_default='3306'
              ;;
          esac

          read -p "Enter $var value, or leave blank to use the default : $val_default : " val

          if [[ -z "$val" ]]; then
            eval "export $var=\"$val_default\""
            u_instance_registry_set "${p_db_id}.${var}" "$val_default"
          else
            eval "export $var=\"$val\""
            u_instance_registry_set "${p_db_id}.${var}" "$val"
          fi

        # Value was previously stored in registry (secrets store)
        # -> just export it.
        else
          eval "export $var=\"$reg_val\""
        fi
      done
    ;;
  esac
}

##
# [abstract] Creates (+ sets up) new database.
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension which does. E.g. :
# @see cwt/extensions/mysql
#
# @param 1 [optional] String : $DB_NAME override.
#
# @example
#   u_db_create
#   u_db_create 'custom_db_name'
#
u_db_create() {
  local p_db_name_override="$1"

  u_db_get_credentials

  if [[ -n "$p_db_name_override" ]]; then
    DB_NAME="$p_db_name_override"
  fi

  u_hook_most_specific -s 'db' -a 'create' -v 'PROVISION_USING'
}

##
# [abstract] Imports given dump file into database.
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension which does. E.g. :
# @see cwt/extensions/mysql
#
# @param 1 String : the dump file path.
# @param 2 [optional] String : $DB_NAME override.
#
# @example
#   u_db_import '/path/to/dump/file.sql'
#   u_db_import '/path/to/dump/file.sql' 'custom_db_name'
#
u_db_import() {
  local p_dump_file_path="$1"
  local p_db_name_override="$2"

  if [[ ! -f "$p_dump_file_path" ]]; then
    echo >&2
    echo "Error in u_db_import() - $BASH_SOURCE line $LINENO: the DB dump file '$p_dump_file_path' is missing or inaccessible." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  u_db_get_credentials

  if [[ -n "$p_db_name_override" ]]; then
    DB_NAME="$p_db_name_override"
  fi

  u_hook_most_specific -s 'db' -a 'import' -v 'PROVISION_USING'
}

##
# [abstract] Exports database to a compressed (tgz) dump file.
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension which does. E.g. :
# @see cwt/extensions/mysql
#
# Important notes : implementations of the hook -s 'db' -a 'export' MUST use the
# following variable in calling scope as output path (resulting file) :
# @var db_dump_file
# This function does not implement the creation of the "raw" DB dump file, but
# it always compresses it immediately (appends ".tgz" to given file path).
# TODO make compression optional ?
#
# @param 1 String : the dump file path.
# @param 2 [optional] String : $DB_NAME override.
#
# @example
#   u_db_export '/path/to/dump/file.sql'
#   u_db_export '/path/to/dump/file.sql' 'custom_db_name'
#
u_db_export() {
  local p_dump_file_path="$1"
  local p_db_name_override="$2"
  local db_dump_dir
  local db_dump_file

  u_db_get_credentials

  if [[ -n "$p_db_name_override" ]]; then
    DB_NAME="$p_db_name_override"
  fi

  # TODO [minor] sanitize $p_dump_file_path ?
  db_dump_file="$p_dump_file_path"
  db_dump_dir="${db_dump_file%/${db_dump_file##*/}}"

  # The "export" action should only have to create a new file. If it already
  # exists, we consider it an error. This case should be explicitly dealt with
  # beforehand (e.g. existing file deleted or moved).
  if [[ -f "$db_dump_file" ]]; then
    echo >&2
    echo "Error in u_db_export() - $BASH_SOURCE line $LINENO: destination file '$db_dump_file' already exists." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi

  if [[ ! -d "$db_dump_dir" ]]; then
    mkdir -p "$db_dump_dir"

    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in u_db_export() - $BASH_SOURCE line $LINENO: failed to create new backup dir '$db_dump_dir'." >&2
      echo "-> Aborting (1)." >&2
      echo >&2
      exit 1
    fi
  fi

  # Implementations MUST use var $db_dump_file as output path (resulting file).
  u_hook_most_specific -s 'db' -a 'export' -v 'PROVISION_USING'

  if [ ! -f "$db_dump_file" ]; then
    echo >&2
    echo "Error in u_db_export() - $BASH_SOURCE line $LINENO: file '$db_dump_file' does not exist." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi

  # Compress & remove uncompressed dump file.
  tar czf "$db_dump_file.tgz" -C "$db_dump_dir" "$db_dump_file"
  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in u_db_export() - $BASH_SOURCE line $LINENO: failed to compress dump file '$db_dump_file'." >&2
    echo "-> Aborting (3)." >&2
    echo >&2
    exit 3
  fi

  rm "$db_dump_file"
  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in u_db_export() - $BASH_SOURCE line $LINENO: failed to remove uncompressed dump file '$db_dump_file'." >&2
    echo "-> Aborting (4)." >&2
    echo >&2
    exit 4
  fi
}

##
# [abstract] Clears (empties) database.
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension which does. E.g. :
# @see cwt/extensions/mysql
#
# @param 1 [optional] String : $DB_NAME override.
#
# @example
#   u_db_clear
#   u_db_clear 'custom_db_name'
#
u_db_clear() {
  local p_db_name_override="$1"

  u_db_get_credentials

  if [[ -n "$p_db_name_override" ]]; then
    DB_NAME="$p_db_name_override"
  fi

  u_hook_most_specific -s 'db' -a 'clear' -v 'PROVISION_USING'
}

##
# Empties database + imports given dump file.
#
# @param 1 String : the dump file path.
# @param 2 [optional] String : $DB_NAME override.
#
# @example
#   u_db_restore '/path/to/dump/file.sql'
#   u_db_restore '/path/to/dump/file.sql' 'custom_db_name'
#
u_db_restore() {
  local p_dump_file_path="$1"
  local p_db_name_override="$2"

  if [[ ! -f "$p_dump_file_path" ]]; then
    echo >&2
    echo "Error in u_db_restore() - $BASH_SOURCE line $LINENO: the DB dump file '$p_dump_file_path' is missing or inaccessible." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  u_db_get_credentials

  if [[ -n "$p_db_name_override" ]]; then
    DB_NAME="$p_db_name_override"
  fi

  u_db_clear
  u_db_import "$p_dump_file_path"
}

##
# Empties database + imports the last (= most recent) dump file available.
#
# @see u_fs_get_most_recent()
# @requires globals CWT_DB_DUMPS_BASE_PATH in calling scope.
#
# @param 1 [optional] String : $DB_NAME override.
#
# @example
#   u_db_restore_last
#   u_db_restore_last 'custom_db_name'
#
u_db_restore_last() {
  u_db_restore "$(u_fs_get_most_recent $CWT_DB_DUMPS_BASE_PATH)" "$@"
}

##
# Creates a routine DB dump backup + progressively deletes old DB dumps.
#
# @requires globals CWT_DB_DUMPS_BASE_PATH in calling scope.
#
# @param 1 [optional] String : 'no-purge' to prevent automatic deletion of old
#   backups.
# @param 2 [optional] String : $DB_NAME override.
#
# @example
#   u_db_restore_last
#   u_db_restore_last 'no-purge'
#   u_db_restore_last '' 'custom_db_name'
#   u_db_restore_last 'no-purge' 'custom_db_name'
#
u_db_routine_backup() {
  local p_no_purge="$1"
  local p_db_name_override="$2"
  local db_routine_new_backup_file

  u_db_get_credentials
  db_routine_new_backup_file="${CWT_DB_DUMPS_BASE_PATH}/local/$(date +"%Y/%m/%d/%H-%M-%S").$DB_ID.sql"

  u_db_export "$db_routine_new_backup_file"

  # TODO [wip] unless 'no-purge' option is set, implement old dumps cleanup.
  # If we had time, this could be implemented with something like :
  # global CWT_DB_BAK_ROUTINE_PURGE "[default]='1m:5,3m:3,6m:2,1y:1' [help]='Custom syntax specifying how many dump files to keep by age. Comma-separated list of quotas - ex: 1m:5 = for backups older than 1 month, keep max 5 files in that month.'"
}
