#!/usr/bin/env bash

##
# Basic database utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#

##
# Exports the complete set of DB info by ID, and (re)sets corresponding values.
#
# Some values may be generated and stored once on first call, e.g. passwords
# when CWT_DB_MODE is set to 'auto' (or prompted when set to 'manual').
#
# @exports DB_ID - defaults to 'default'.
# @exports DB_DRIVER - defaults to 'mysql'.
# @exports DB_HOST - defaults to 'localhost'.
# @exports DB_PORT - defaults to '3306' or '5432' if DB_DRIVER is 'pgsql'.
# @exports DB_NAME - defaults to '*' (meaning all databases at once, or global).
# @exports DB_USER - defaults to first 16 characters of DB_ID.
# @exports DB_PASS - defaults to 14 random characters.
# @exports DB_ADMIN_USER - defaults to DB_USER.
# @exports DB_ADMIN_PASS - defaults to DB_PASS.
# @exports DB_TABLES_SKIP_DATA - defaults to an empty string.
#
# This function also exports a prefixed version of each variable with DB_ID.
# @exports <DB_ID>_DB_* (ex: if DB_ID='default', will export DEFAULT_DB_NAME, etc.)
#
# @requires the following globals in calling scope :
# - INSTANCE_DOMAIN
# - CWT_DB_MODE
# - CWT_DB_DUMPS_BASE_PATH
# @see cwt/extensions/db/global.vars.sh
#
# Uses the following env. var. if it is defined in current shell scope to select
# which database credentials to load :
# - CWT_DB_ID
# This allows to operate on different databases from the same project instance.
# See also the first parameter to this function documented below.
#
# If CWT_DB_MODE is set to 'auto' or 'manual', the first call to this function
# will generate or prompt once the values for these globals.
# Subsequent calls to this function will then read these values from registry.
# @see cwt/instance/registry_set.sh
# @see cwt/instance/registry_get.sh
#
# @param 1 [optional] String : unique DB identifier. Defaults to 'default'.
#   Important note : DB_ID values are restricted to alphanumerical characters
#   and underscores (i.e. like variable names).
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#
# @example
#   # Calling this funcion without arguments = use defaults mentionned above,
#   # depending on CWT_DB_MODE (see cwt/extensions/db/global.vars.sh).
#   u_db_set
#   # Result :
#   # - all DB_* variables exported contain the 'default' DB values.
#   # - a copy of every variable prefixed with DB_ID is exported. E.g. :
#   echo "$DEFAULT_DB_NAME"
#   echo "$DEFAULT_DB_USER"
#   # Etc.
#
#   # Explicitly set DB_ID (TODO [wip] write tests for multi-db projects).
#   # Alternatively, a local variable $CWT_DB_ID may be used in calling scope.
#   u_db_set id_example
#   # Or :
#   CWT_DB_ID='id_example'
#   u_db_set
#   # Result :
#   echo "$ID_EXAMPLE_DB_NAME"
#   echo "$ID_EXAMPLE_DB_USER"
#   # Etc.
#
#   # If multiple consecutive calls to this function are made in current shell
#   # scope for the same DB_ID (or without - fallback to 'default'), previously
#   # exported values will not be re-loaded.
#   # The 2nd arg is a flag which can force re-loading these values. This allows
#   # to support cases where some stored values (e.g. registry) might be updated.
#   u_db_set id_example 1
#
u_db_set() {
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
  else
    db_id="$p_db_id"
  fi
  u_str_sanitize_var_name "$db_id" 'db_id'

  if [[ -n "$DB_ID" ]]; then
    # If DB credentials vars are already exported in current shell scope for given
    # db_id, no need to reload (unless explicitly asked).
    if [[ "$DB_ID" == "$db_id" ]] && [[ -z "$p_force_reload" ]]; then
      return
    fi
    # When DB_ID was previously set in current shell scope AND it is different
    # (or the force reload is requested), then we first need to USET all the
    # unprefixed DB_* variables so that the default values are properly set
    # below.
    u_db_unset
  fi

  export DB_ID="$db_id"

  # Give a chance to other extensions to preset non-readonly env vars, including
  # per DB_ID.
  hook -s 'db' -a 'env_preset' -v 'INSTANCE_TYPE PROVISION_USING DB_ID'

  case "$CWT_DB_MODE" in
    # Some environments do not require CWT to handle DB credentials at all.
    # In these cases, the following global env vars should be provided in
    # calling scope :
    # - $DB_USER
    # - $DB_PASS
    # These fallback values are provided if not set :
    # - $DB_DRIVER defaults to mysql
    # - $DB_NAME defaults to *
    # - $DB_HOST defaults to localhost
    # - $DB_PORT defaults to 3306 or 5432 if DB_DRIVER is 'pgsql'
    # - $DB_ADMIN_USER defaults to $DB_USER
    # - $DB_ADMIN_PASS defaults to $DB_PASS
    # - $DB_TABLES_SKIP_DATA defaults to an empty string
    none)
      if [[ -z "$DB_DRIVER" ]]; then
        export DB_DRIVER='mysql'
      else
        export DB_DRIVER
      fi
      if [[ -z "$DB_NAME" ]]; then
        export DB_NAME='*'
      else
        export DB_NAME
      fi
      if [[ -z "$DB_HOST" ]]; then
        export DB_HOST='localhost'
      else
        export DB_HOST
      fi
      if [[ -z "$DB_PORT" ]]; then
        case "$DB_DRIVER" in
          pgsql)  export DB_PORT='5432' ;;
          *)      export DB_PORT='3306' ;;
        esac
      else
        export DB_PORT
      fi
      if [[ -z "$DB_ADMIN_USER" ]]; then
        export DB_ADMIN_USER="$DB_USER"
      else
        export DB_ADMIN_USER
      fi
      if [[ -z "$DB_ADMIN_PASS" ]]; then
        export DB_ADMIN_PASS="$DB_PASS"
      else
        export DB_ADMIN_PASS
      fi
      if [[ -z "$DB_TABLES_SKIP_DATA" ]]; then
        export DB_TABLES_SKIP_DATA=""
      else
        export DB_TABLES_SKIP_DATA
      fi
      return
      ;;

    # The 'auto' mode means we only store the password, which gets generated
    # once on first call (and read otherwise).
    # Other values will be assigned default values unless the following global
    # env vars are already set in calling scope :
    # - $DB_DRIVER defaults to mysql
    # - $DB_NAME defaults to $DB_ID
    # - $DB_USER defaults to $DB_ID
    # - $DB_HOST defaults to localhost
    # - $DB_PORT defaults to 3306 or 5432 if DB_DRIVER is 'pgsql'
    # - $DB_ADMIN_USER defaults to $DB_USER
    # - $DB_ADMIN_PASS defaults to $DB_PASS
    # - $DB_TABLES_SKIP_DATA defaults to an empty string
    auto)
      if [[ -z "$DB_DRIVER" ]]; then
        export DB_DRIVER='mysql'
      else
        export DB_DRIVER
      fi
      if [[ -z "$DB_NAME" ]]; then
        export DB_NAME='*'
      else
        export DB_NAME
      fi
      if [[ -z "$DB_USER" ]]; then
        export DB_USER="$DB_ID"
        # Limit automatically generated user name to 16 or 32 characters,
        # depending on the driver used by current database ID. Prevents errors
        # like "MySQL ERROR 1470 (HY000) String is too long for user name".
        # Warning : this creates naming collision risks (considered edge case).
        case "$DB_DRIVER" in
          pgsql) DB_USER="${DB_USER:0:32}" ;;
          mysql) DB_USER="${DB_USER:0:16}" ;;
        esac
      else
        export DB_USER
      fi
      if [[ -z "$DB_HOST" ]]; then
        export DB_HOST='localhost'
      else
        export DB_HOST
      fi
      if [[ -z "$DB_PORT" ]]; then
        case "$DB_DRIVER" in
          pgsql)  export DB_PORT='5432' ;;
          *)      export DB_PORT='3306' ;;
        esac
      else
        export DB_PORT
      fi
      if [[ -z "$DB_TABLES_SKIP_DATA" ]]; then
        export DB_TABLES_SKIP_DATA=""
      else
        export DB_TABLES_SKIP_DATA
      fi

      if [[ -z "$DB_PASS" ]]; then
        # Attempts to load password from registry (secrets store).
        # Warning : if cwt/extensions/file_registry is used as registry storage
        # backend, no encryption will be used. This may be fine for local dev - e.g.
        # in temporary virtual machines inaccessible to the outside world, but
        # it is obviously a security risk.
        reg_val=''
        u_instance_registry_get "${db_id}.DB_PASS"

        # Generate random local instance DB password and store it for subsequent
        # calls.
        if [[ -z "$reg_val" ]]; then
          export DB_PASS="$(< /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo)"
          u_instance_registry_set "${db_id}.DB_PASS" "$DB_PASS"
        else
          export DB_PASS="$reg_val"
        fi
      else
        export DB_PASS
      fi

      export DB_ADMIN_USER="${DB_ADMIN_USER:=$DB_USER}"
      export DB_ADMIN_PASS="${DB_ADMIN_PASS:=$DB_PASS}"
    ;;

    # 'manual' mode requires terminal (prompts) on first call.
    manual)
      local var
      local val
      local val_default
      local vars_to_getset='DB_DRIVER DB_HOST DB_PORT DB_NAME DB_USER DB_PASS DB_ADMIN_USER DB_ADMIN_PASS'

      for var in $vars_to_getset; do
        val=''
        val_default=''
        reg_val=''
        u_instance_registry_get "${db_id}.${var}"

        # Value is not found in registry (secrets store)
        # -> init & store.
        if [[ -z "$reg_val" ]]; then
          case "$var" in
            DB_DRIVER)
              val_default='mysql'
              ;;
            DB_HOST)
              val_default='localhost'
              ;;
            DB_PORT)
              val_default='3306'
              case "$DB_DRIVER" in pgsql)
                val_default='5432'
              esac
              ;;
            DB_NAME)
              val_default='*'
              ;;
            DB_USER)
              val_default="${DB_ID:0:16}"
              # Limit automatically generated user name to 16 or 32 characters,
              # depending on the driver used by current database ID. Prevents errors
              # like "MySQL ERROR 1470 (HY000) String is too long for user name".
              # Warning : this creates naming collision risks (considered edge case).
              case "$DB_DRIVER" in
                pgsql)  val_default="${val_default:0:32}" ;;
                mysql)  val_default="${val_default:0:16}" ;;
              esac
              ;;
            DB_PASS)
              val_default=`< /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo`
              ;;
            DB_ADMIN_USER)
              val_default="$DB_USER"
              ;;
            DB_ADMIN_PASS)
              val_default="$DB_PASS"
              ;;
            DB_TABLES_SKIP_DATA)
              val_default=""
              ;;
          esac

          read -p "Enter $var value, or leave blank to use the default : $val_default : " val

          if [[ -z "$val" ]]; then
            export "$var=$val_default"
            u_instance_registry_set "${db_id}.${var}" "$val_default"
          else
            export "$var=$val"
            u_instance_registry_set "${db_id}.${var}" "$val"
          fi

        # Value was previously stored in registry (secrets store)
        # -> just export it.
        else
          export "$var=$reg_val"
        fi
      done
    ;;
  esac

  # Finally, export prefixed DB_* vars.
  local v
  local db_var
  local prefixed_db_var

  u_db_vars_list

  for v in $db_vars_list; do
    db_var="DB_$v"
    prefixed_db_var="${db_id}_${db_var}"
    u_str_uppercase "$prefixed_db_var" 'prefixed_db_var'
    export "$prefixed_db_var=${!db_var}"
  done
}

##
# Unsets all DB_* variables so that the correct values can then be (re)set.
#
# Required because the default values would not be correctly set if we switched
# between databases in the same shell scope - i.e. as in u_db_set_all()
#
# @see u_db_set()
#
u_db_unset() {
  local v
  u_db_vars_list
  for v in $db_vars_list; do
    eval "unset DB_$v"
  done
}

##
# Gets an array of all database IDs defined in current project instance.
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to a variable subject to collision in calling scope.
#
# @var db_ids
#
# @example
#   db_ids=()
#   u_db_get_ids
#   echo ${db_ids[@]}"
#
u_db_get_ids() {
  local db_id
  local multi_db_ids=''

  # Support multi-DB projects defined using the "append"-type global CWT_DB_IDS.
  if [[ -n "$CWT_DB_IDS" ]]; then
    for db_id in $CWT_DB_IDS; do
      u_array_add_once "$db_id" db_ids
    done
  fi

  # Let extensions define their own additional DB_IDs.
  hook -s 'db' -a 'set_multi_db_ids' -v 'INSTANCE_TYPE'
  if [[ -n "$multi_db_ids" ]]; then
    for db_id in $multi_db_ids; do
      u_array_add_once "$db_id" db_ids
    done
  fi
}

##
# Exports all locally-defined DB credentials (multi-DB support).
#
# There are 2 ways to declare the different databases that the local project
# instance will use :
#   1. Using the read-only "append-type" global CWT_DB_IDS
#   2. Implementing hook -s 'db' -a 'set_multi_db_ids' -v 'INSTANCE_TYPE'
#     (adding space-separated values to scoped variable multi_db_ids).
# @see u_db_set()
#
# @example
#   u_db_set_all
#   # Result (given 2 ids : 'default' + 'example') :
#   echo "$DB_ID" # <- Prints 'default'
#   echo "$DB_USER" # <- Prints the user name for 'default' database.
#   echo "$EXAMPLE_DB_USER" # <- Prints the user name for 'example' database.
#   # etc.
#
u_db_set_all() {
  local db_id
  local db_ids=()

  u_db_get_ids

  if [[ -n "${db_ids[@]}" ]]; then
    for db_id in "${db_ids[@]}"; do
      # Default site will be loaded last, see below.
      case "$db_id" in 'default')
        continue
      esac
      u_db_set "$db_id"
    done
  fi

  # Default DB is loaded last. This allows for the DB "selected" by default
  # after CWT bootstrap is done to be DB_ID='default'.
  u_db_set
}

##
# Single source of truth : get the list of DB vars.
#
# This funtion writes its result to a variable subject to collision in calling
# scope :
# @var db_vars_list
#
# @example
#   u_db_vars_list
#   echo "$db_vars_list"
#
u_db_vars_list() {
  db_vars_list='ID DRIVER HOST PORT NAME USER PASS ADMIN_USER ADMIN_PASS TABLES_SKIP_DATA'
}

##
# [abstract] Detects if a database already exists.
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension which does. E.g. :
# @see cwt/extensions/mysql
# @see cwt/extensions/pgsql
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:db a:exists v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:db a:exists v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# @param 1 String : the database name to check.
# @param 2 [optional] String : unique DB identifier. Defaults to 'default'.
# @param 3 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#
# @example
#   if u_db_exists 'my_db_name'; then
#     echo "Ok, 'my_db_name' exists."
#   else
#     echo "Error : 'my_db_name' does not exist (or I do not have permission to access it)."
#   fi
#
u_db_exists() {
  local p_db_name="$1"
  local db_exists=''

  u_db_set "$2" "$3"
  u_hook_most_specific -s 'db' -a 'exists' -v 'DB_DRIVER DB_ID INSTANCE_TYPE'

  case "$db_exists" in true)
    return 1
  esac

  return 0
}

##
# [abstract] Creates (+ sets up) new database.
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension which does. E.g. :
# @see cwt/extensions/mysql
# @see cwt/extensions/pgsql
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:db a:create v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:db a:create v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# @param 1 [optional] String : unique DB identifier. Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#
# @example
#   u_db_create
#
u_db_create() {
  u_db_set "$1" "$2"
  u_hook_most_specific -s 'db' -a 'create' -v 'DB_DRIVER DB_ID INSTANCE_TYPE'
}

##
# [abstract] Destroys given database.
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension which does. E.g. :
# @see cwt/extensions/mysql
# @see cwt/extensions/pgsql
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:db a:destroy v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:db a:destroy v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# @param 1 [optional] String : unique DB identifier. Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#
# @example
#   u_db_destroy
#
u_db_destroy() {
  u_db_set "$1" "$2"
  u_hook_most_specific -s 'db' -a 'destroy' -v 'DB_DRIVER DB_ID INSTANCE_TYPE'
}

##
# [abstract] Imports given dump file into database.
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension which does. E.g. :
# @see cwt/extensions/mysql
# @see cwt/extensions/pgsql
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:db a:import v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:db a:import v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
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
# @param 2 [optional] String : unique DB identifier. Defaults to 'default'.
# @param 3 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#
# @example
#   u_db_import '/path/to/dump/file.sql.tgz'
#
u_db_import() {
  local p_dump_file_path="$1"
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

  u_db_set "$2" "$3"

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
  u_hook_most_specific -s 'db' -a 'import' -v 'DB_DRIVER DB_ID INSTANCE_TYPE'

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
# @see cwt/extensions/pgsql
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:db a:backup v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:db a:backup v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# Important notes : implementations of the hook -s 'db' -a 'backup' MUST use the
# following variable in calling scope as output path (resulting file) :
#
# @var db_dump_file
#
# This function does not implement the creation of the "raw" DB dump file, but
# it always compresses it immediately (appends ".tgz" to given file path).
#
# @param 1 String : the dump file path.
# @param 2 [optional] String : unique DB identifier. Defaults to 'default'.
# @param 3 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#
# @example
#   u_db_backup '/path/to/dump/file.sql'
#
u_db_backup() {
  if [[ -z "$CWT_DB_DUMPS_BASE_PATH" ]]; then
    echo >&2
    echo "Error in u_db_backup() - $BASH_SOURCE line $LINENO: the required global 'CWT_DB_DUMPS_BASE_PATH' is undefined." >&2
    echo "Current instance must be (re)initialized with the 'db' extension enabled." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  local p_dump_file_path="$1"

  local db_dump_dir
  local db_dump_file
  local db_dump_file_name

  u_db_set "$2" "$3"

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

  # Implementations MUST use var $db_dump_file as output path (resulting file).
  u_hook_most_specific -s 'db' -a 'backup' -v 'DB_DRIVER DB_ID INSTANCE_TYPE'

  if [ ! -f "$db_dump_file" ]; then
    echo >&2
    echo "Error in u_db_backup() - $BASH_SOURCE line $LINENO: file '$db_dump_file' does not exist." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi

  # Compress & remove uncompressed dump file.
  db_dump_file_name="${db_dump_file##*/}"
  tar czf "$db_dump_file.tgz" -C "$db_dump_dir" "$db_dump_file_name"
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
# @see cwt/extensions/pgsql
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:db a:clear v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:db a:clear v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# @param 1 [optional] String : unique DB identifier. Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#
# @example
#   u_db_clear
#
u_db_clear() {
  u_db_set "$1" "$2"
  u_hook_most_specific -s 'db' -a 'clear' -v 'DB_DRIVER DB_ID INSTANCE_TYPE'
}

##
# Empties database + imports given dump file.
#
# @param 1 String : the dump file path.
# @param 2 [optional] String : unique DB identifier. Defaults to 'default'.
# @param 3 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#
# @example
#   u_db_restore '/path/to/dump/file.sql'
#   u_db_restore '/path/to/dump/file.sql' 'my_custom_db_id'
#
u_db_restore() {
  local p_dump_file_path="$1"

  if [[ ! -f "$p_dump_file_path" ]]; then
    echo >&2
    echo "Error in u_db_restore() - $BASH_SOURCE line $LINENO: the DB dump file '$p_dump_file_path' is missing or inaccessible." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  u_db_clear "$2" "$3"
  u_db_import "$p_dump_file_path" "$2" "$3"
}

##
# Empties database + imports the last (= most recent) dump file available.
#
# @see u_fs_get_most_recent()
# @requires globals CWT_DB_DUMPS_BASE_PATH in calling scope.
#
# @param 1 [optional] String : unique DB identifier. Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#
# @example
#   u_db_restore_last
#
u_db_restore_last() {
  if [[ -z "$CWT_DB_DUMPS_BASE_PATH" ]]; then
    echo >&2
    echo "Error in u_db_restore_last() - $BASH_SOURCE line $LINENO: the required global 'CWT_DB_DUMPS_BASE_PATH' is undefined." >&2
    echo "Current instance must be (re)initialized with the 'db' extension enabled." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  local p_db_id="$1"

  if [[ -z "$p_db_id" ]]; then
    p_db_id='default'
  fi

  # TODO how to get most recent file from multiple dirs, because we may want to
  # restore a recently downloaded dump from a remote instance, and we don't
  # want to mix different databases together here ?
  u_db_restore "$(u_fs_get_most_recent $CWT_DB_DUMPS_BASE_PATH/local/$p_db_id)" "$p_db_id" "$2"
}

##
# Creates a routine DB dump backup.
#
# @requires globals CWT_DB_DUMPS_BASE_PATH in calling scope.
#
# @param 1 [optional] String : unique DB identifier. Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to a variable subject to collision in calling scope.
#
# @var routine_dump_file
#
# @example
#   u_db_routine_backup
#
u_db_routine_backup() {
  if [[ -z "$CWT_DB_DUMPS_BASE_PATH" ]]; then
    echo >&2
    echo "Error in u_db_routine_backup() - $BASH_SOURCE line $LINENO: the required global 'CWT_DB_DUMPS_BASE_PATH' is undefined." >&2
    echo "Current instance must be (re)initialized with the 'db' extension enabled." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  u_db_set $@

  local db_routine_new_backup_file
  local db_backup_file_middle
  local db_backup_file_ext

  db_backup_file_middle="$DB_NAME"
  case "$DB_NAME" in '*')
    db_backup_file_middle="all-databases"
  esac

  # TODO [wip] Allow setting dump file extension in DB settings ?
  # Using generic extension 'dump' for now, with hardcoded extension for mysql
  # and pgsql.
  db_backup_file_ext='dump'
  case "$DB_DRIVER" in mysql|pgsql)
    db_backup_file_ext='sql'
  esac

  db_routine_new_backup_file="$CWT_DB_DUMPS_BASE_PATH/local/$DB_ID/$(date +"%Y/%m/%d/%H-%M-%S")_$db_backup_file_middle.$db_backup_file_ext"

  u_db_backup "$db_routine_new_backup_file" "$1" "$2"

  # Some tasks need the generated dump file path.
  routine_dump_file="${db_routine_new_backup_file}.tgz"
}

##
# Gets local instance DB dump filepath.
#
# Optionally creates a new routine dump first.
#
# @param 1 [optional] String : pass 'new' to create new dump instead of
#   returning most recent among existing local DB dump files.
#   Pass 'initial' to get a dump file whose name matches 'initial.*'.
# @param 2 [optional] String : unique DB identifier. Defaults to 'default'.
# @param 3 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#
# @example
#   most_recent_dump_file="$(u_db_get_dump)"
#   echo "Result = '$most_recent_dump_file'"
#
#   new_routine_dump_file="$(u_db_get_dump 'new')"
#   echo "Result = '$new_routine_dump_file'"
#
#   initial_dump_file="$(u_db_get_dump 'initial')"
#   echo "Result = '$initial_dump_file'"
#
u_db_get_dump() {
  local p_option="$1"
  local p_db_id="$2"
  local dump_to_return

  if [[ -z "$p_db_id" ]]; then
    p_db_id='default'
  fi

  if [[ -n "$p_option" ]]; then
    case "$p_option" in
      new)
        u_db_routine_backup "$p_db_id" "$3"
        dump_to_return="$routine_dump_file"
        ;;
      initial)
        local initial_dump_match
        u_fs_file_list "$CWT_DB_DUMPS_BASE_PATH/local/$p_db_id" 'initial.*'
        for initial_dump_match in $file_list; do
          dump_to_return="$CWT_DB_DUMPS_BASE_PATH/local/$p_db_id/$initial_dump_match"
        done
        ;;
    esac
  else
    dump_to_return="$(u_fs_get_most_recent $CWT_DB_DUMPS_BASE_PATH/local/$p_db_id)"
  fi

  if [[ -f "$dump_to_return" ]]; then
    echo "$dump_to_return"
  fi
}
