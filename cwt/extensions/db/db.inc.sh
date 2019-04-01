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
# @see cwt/extensions/db/global.vars.sh
#
# If CWT_DB_MODE is set to 'auto' or 'manual', the first call to this function
# will generate *once* the following globals :
#
# @exports DB_ID - defaults to sanitized "$INSTANCE_DOMAIN".
# @exports DB_NAME - defaults to "$DB_ID".
# @exports DB_USERNAME - defaults to first 16 characters of DB_ID.
# @exports DB_PASSWORD - defaults to 14 random characters.
# @exports DB_ADMIN_USERNAME - defaults to DB_USERNAME.
# @exports DB_ADMIN_PASSWORD - defaults to DB_PASSWORD.
# @exports DB_HOST - defaults to 'localhost'.
# @exports DB_PORT - defaults to '3306'.
#
# Subsequent calls to this function will read said values from registry.
# @see cwt/instance/registry_set.sh
# @see cwt/instance/registry_get.sh
#
# @param 1 [optional] String : unique identifier for requested DB (defaults to
#   sanitized INSTANCE_DOMAIN global).
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#
# @example
#   # Calling this funcion without arguments = use defaults mentionned above,
#   # depending on CWT_DB_MODE (see cwt/extensions/db/global.vars.sh).
#   u_db_get_credentials
#
#   # Explicitly set DB_ID (TODO [wip] test multi-db projects).
#   # Alternatively, a local variable $CWT_DB_ID may be used in calling scope.
#   u_db_get_credentials my_custom_db_id
#   # Or :
#   CWT_DB_ID='my_custom_db_id'
#   u_db_get_credentials
#
#   # If called in current shell scope once, exported values will prevent
#   # re-loading values. TODO [wip] implement "static" keyed sets of vars ?
#   # Meanwhile, the 2nd arg is a flag which can force re-loading these values.
#   u_db_get_credentials my_custom_db_id 1
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
  local db_id
  local reg_val

  if [[ -z "$p_db_id" ]]; then
    if [[ -n "$CWT_DB_ID" ]]; then
      db_id="$CWT_DB_ID"
    else
      db_id='default'
    fi
  fi

  u_str_sanitize_var_name "$db_id" 'db_id'

  # If DB credentials vars are already exported in current shell scope, no need
  # to carry on.
  if [[ -n "$DB_ID" ]] && [[ "$DB_ID" == "$db_id" ]] && [[ -z "$p_force_reload" ]]; then
    return
  fi
  export DB_ID="$db_id"

  case "$CWT_DB_MODE" in
    # Some environments do not require CWT to handle DB credentials at all.
    # In these cases, the following local env vars should be manually provided :
    # - $DB_NAME
    # - $DB_USERNAME
    # - $DB_PASSWORD
    # - $DB_HOST
    # These fallback values are provided if not set :
    # - $DB_PORT defaults to 3306
    # - $DB_ADMIN_USERNAME defaults to $DB_USERNAME
    # - $DB_ADMIN_PASSWORD defaults to $DB_PASSWORD
    none)
      if [[ -z "$DB_PORT" ]]; then
        export DB_PORT=3306
      fi
      if [[ -z "$DB_ADMIN_USERNAME" ]]; then
        export DB_ADMIN_USERNAME="$DB_USERNAME"
      fi
      if [[ -z "$DB_ADMIN_PASSWORD" ]]; then
        export DB_ADMIN_PASSWORD="$DB_PASSWORD"
      fi
      return
      ;;

    # The 'auto' mode means we only store the password, which gets generated
    # once on first call (and read otherwise).
    # Other values will be assigned default values unless the following local
    # env vars are already set in calling scope :
    # - $DB_NAME defaults to $DB_ID
    # - $DB_USERNAME defaults to $DB_ID
    # - $DB_HOST defaults to localhost
    # - $DB_PORT defaults to 3306
    # - $DB_ADMIN_USERNAME defaults to $DB_USERNAME
    # - $DB_ADMIN_PASSWORD defaults to $DB_PASSWORD
    auto)
      export DB_NAME="${DB_NAME:=$DB_ID}"
      export DB_USERNAME="${DB_USERNAME:=$DB_ID}"
      export DB_HOST="${DB_HOST:=localhost}"
      export DB_PORT="${DB_PORT:=3306}"

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
      u_instance_registry_get "${db_id}.DB_PASSWORD"

      # Generate random local instance DB password and store it for subsequent
      # calls.
      if [[ -z "$reg_val" ]]; then
        export DB_PASSWORD=`< /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo`
        u_instance_registry_set "${db_id}.DB_PASSWORD" "$DB_PASSWORD"
      else
        export DB_PASSWORD="$reg_val"
      fi

      export DB_ADMIN_USERNAME="${DB_ADMIN_USERNAME:=$DB_USERNAME}"
      export DB_ADMIN_PASSWORD="${DB_ADMIN_PASSWORD:=$DB_PASSWORD}"
    ;;

    # 'manual' mode requires terminal (prompts) on first call.
    manual)
      local var
      local val
      local val_default
      local vars_to_getset='DB_NAME DB_USERNAME DB_PASSWORD DB_ADMIN_USERNAME DB_ADMIN_PASSWORD DB_HOST DB_PORT'

      for var in $vars_to_getset; do
        val=''
        val_default=''
        reg_val=''
        u_instance_registry_get "${db_id}.${var}"

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
            DB_ADMIN_USERNAME)
              val_default="$DB_USERNAME"
              ;;
            DB_ADMIN_PASSWORD)
              val_default="$DB_PASSWORD"
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
            u_instance_registry_set "${db_id}.${var}" "$val_default"
          else
            eval "export $var=\"$val\""
            u_instance_registry_set "${db_id}.${var}" "$val"
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
# [abstract] Destroys given database.
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension which does. E.g. :
# @see cwt/extensions/mysql
#
# @param 1 [optional] String : $DB_NAME override.
#
# @example
#   u_db_destroy
#   u_db_destroy 'custom_db_name'
#
u_db_destroy() {
  local p_db_name_override="$1"

  u_db_get_credentials

  if [[ -n "$p_db_name_override" ]]; then
    DB_NAME="$p_db_name_override"
  fi

  u_hook_most_specific -s 'db' -a 'destroy' -v 'PROVISION_USING'
}

##
# [abstract] Imports given dump file into database.
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension which does. E.g. :
# @see cwt/extensions/mysql
#
# Important notes : implementations of the hook -s 'db' -a 'import' MUST use the
# following variable in calling scope as input path (source file) :
#
# @var db_dump_file
#
# This function does not implement the import of the "raw" DB dump file, but
# it always checks if it must be previously uncompressed (detects the ".tgz"
# extension).
#
# @param 1 String : the dump file path.
# @param 2 [optional] String : $DB_NAME override.
#
# @example
#   u_db_import '/path/to/dump/file.sql.tgz'
#   u_db_import '/path/to/dump/file.sql' 'custom_db_name'
#
u_db_import() {
  local p_dump_file_path="$1"
  local p_db_name_override="$2"
  local db_dump_dir
  local db_dump_file
  local leaf

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

  db_dump_file="$p_dump_file_path"

  u_fs_extract_in_place "$db_dump_file"
  file_was_uncompressed=$?

  # When input file is an archive, we assume the uncompressed file will be
  # named exactly like the archive without its extension, e.g. :
  # - my-dump.sql.tgz -> my-dump.sql
  # - my-dump.sql.tar.gz -> my-dump.sql
  if [[ $file_was_uncompressed -eq 0 ]]; then

    # Deal with some compression formats using a double extension.
    case "$db_dump_file" in *.tar.bz2|*.tar.gz|*.tar.xz)
      leaf="${db_dump_file##*.}"
      db_dump_file="${db_dump_file%.$leaf}"
      leaf="${db_dump_file##*.}"
      db_dump_file="${db_dump_file%.$leaf}"
    esac

    # Deal with some compression formats using a single extension.
    case "$db_dump_file" in *.cbt|*.tbz2|*.tgz|*.txz|*.tar|*.gz|*.zip|*.bz2|*.z)
      leaf="${db_dump_file##*.}"
      db_dump_file="${db_dump_file%.$leaf}"
    esac

    if [[ ! -f "$db_dump_file" ]]; then
      echo >&2
      echo "Error in u_db_import() - $BASH_SOURCE line $LINENO: missing uncompressed dump file '$db_dump_file'." >&2
      echo "-> Aborting (2)." >&2
      echo >&2
      exit 2
    fi
  fi

  # Implementations MUST use var $db_dump_file as input path (source file).
  u_hook_most_specific -s 'db' -a 'import' -v 'PROVISION_USING'

  # Remove uncompressed version of the dump when we're done.
  if [[ $file_was_uncompressed -eq 0 ]]; then
    rm "$db_dump_file"
    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in u_db_import() - $BASH_SOURCE line $LINENO: failed to remove uncompressed dump file '$db_dump_file'." >&2
      echo "-> Aborting (3)." >&2
      echo >&2
      exit 3
    fi
  fi
}

##
# [abstract] Backs up (= exports = saves) database to a compressed (tgz) dump file.
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension which does. E.g. :
# @see cwt/extensions/mysql
#
# Important notes : implementations of the hook -s 'db' -a 'backup' MUST use the
# following variable in calling scope as output path (resulting file) :
#
# @var db_dump_file
#
# This function does not implement the creation of the "raw" DB dump file, but
# it always compresses it immediately (appends ".tgz" to given file path).
#
# TODO [evol] make compression optional ?
#
# @param 1 String : the dump file path.
# @param 2 [optional] String : $DB_NAME override.
#
# @example
#   u_db_backup '/path/to/dump/file.sql'
#   u_db_backup '/path/to/dump/file.sql' 'custom_db_name'
#
u_db_backup() {
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

  # The "backup" action should only have to create a new file. If it already
  # exists, we consider it an error. This case should be explicitly dealt with
  # beforehand (e.g. existing file deleted or moved).
  if [[ -f "$db_dump_file" ]]; then
    echo >&2
    echo "Error in u_db_backup() - $BASH_SOURCE line $LINENO: destination file '$db_dump_file' already exists." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi

  if [[ ! -d "$db_dump_dir" ]]; then
    mkdir -p "$db_dump_dir"

    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in u_db_backup() - $BASH_SOURCE line $LINENO: failed to create new backup dir '$db_dump_dir'." >&2
      echo "-> Aborting (1)." >&2
      echo >&2
      exit 1
    fi
  fi

  # TODO should we trigger the hook that resets all filesystem ownership and
  # permissions here ?

  # Implementations MUST use var $db_dump_file as output path (resulting file).
  u_hook_most_specific -s 'db' -a 'backup' -v 'PROVISION_USING'

  if [ ! -f "$db_dump_file" ]; then
    echo >&2
    echo "Error in u_db_backup() - $BASH_SOURCE line $LINENO: file '$db_dump_file' does not exist." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi

  # Compress & remove uncompressed dump file.
  tar czf "$db_dump_file.tgz" -C "$db_dump_dir" "$db_dump_file"
  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in u_db_backup() - $BASH_SOURCE line $LINENO: failed to compress dump file '$db_dump_file'." >&2
    echo "-> Aborting (3)." >&2
    echo >&2
    exit 3
  fi

  rm "$db_dump_file"
  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in u_db_backup() - $BASH_SOURCE line $LINENO: failed to remove uncompressed dump file '$db_dump_file'." >&2
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
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to a variable subject to collision in calling scope.
#
# @var routine_dump_file
#
# @example
#   u_db_routine_backup
#   u_db_routine_backup 'no-purge'
#   u_db_routine_backup '' 'custom_db_name'
#   u_db_routine_backup 'no-purge' 'custom_db_name'
#
u_db_routine_backup() {
  local p_no_purge="$1"
  local p_db_name_override="$2"
  local db_routine_new_backup_file

  # TODO [wip] Allow setting dump file extension in DB settings ?
  # Using generic extension 'dump' for now.
  u_db_get_credentials
  db_routine_new_backup_file="$CWT_DB_DUMPS_BASE_PATH/local/$DB_ID/$(date +"%Y/%m/%d/%H-%M-%S").dump"

  u_db_backup "$db_routine_new_backup_file"

  # TODO [wip] unless 'no-purge' option is set, implement old dumps cleanup.
  # If we had time, this could be implemented with something like :
  # global CWT_DB_BAK_ROUTINE_PURGE "[default]='1m:5,3m:3,6m:2,1y:1' [help]='Custom syntax specifying how many dump files to keep by age. Comma-separated list of quotas - ex: 1m:5 = for backups older than 1 month, keep max 5 files in that month.'"

  # Some tasks need the generated dump file path.
  routine_dump_file="$db_routine_new_backup_file"
}

##
# Gets the most recent local instance DB dump.
#
# Optionally creates a new routine dump first.
#
# @param 1 [optional] String : pass 'new' to create new dump instead of
#   returning most recent among existing local DB dump files.
#
# @example
#   most_recent_dump_file="$(u_db_get_dump)"
#   echo "Result = '$most_recent_dump_file'"
#
#   new_routine_dump_file="$(u_db_get_dump 'new')"
#   echo "Result = '$new_routine_dump_file'"
#
u_db_get_dump() {
  local p_option="$1"
  local dump_to_return

  if [[ -n "$p_option" ]]; then
    case "$p_option" in new)
      u_db_routine_backup
      dump_to_return="$routine_dump_file"
    esac
  else
    dump_to_return="$(u_fs_get_most_recent $CWT_DB_DUMPS_BASE_PATH)"
  fi

  if [[ ! -f "$dump_to_return" ]]; then
    echo >&2
    echo "Error in u_db_get_dump() - $BASH_SOURCE line $LINENO: no DB dump file was found." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  echo "$dump_to_return"
}
