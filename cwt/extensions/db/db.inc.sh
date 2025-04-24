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
# @exports DB_ID - defaults to the first entry in CWT_IDS or 'default'.
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
  local cwt_db_id
  local reg_val

  # Debug.
  if [[ -n "$CWT_DB_DEBUG" ]]; then
    echo "u_db_set $p_db_id"
  fi

  if [[ -z "$p_db_id" ]]; then
    # TODO deprecate fallback to probably unused CWT_DB_ID ?
    if [[ -n "$CWT_DB_ID" ]]; then
      db_id="$CWT_DB_ID"
    elif [[ -n "$CWT_DB_IDS" ]]; then
      for cwt_db_id in $CWT_DB_IDS; do
        db_id="$cwt_db_id"
        break
      done
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
    case "$DB_ID" in "$db_id")
      if [[ -z "$p_force_reload" ]]; then
        if [[ -n "$CWT_DB_DEBUG" ]]; then
          echo "DB_ID:$DB_ID == db_id:$db_id -> skip reload"
        fi
        return
      fi
    esac

    # When DB_ID was previously set in current shell scope AND it is different
    # (or the force reload is requested), then we first need to UNSET all the
    # unprefixed DB_* variables so that the default values are properly set
    # below.
    u_db_unset
  fi

  export DB_ID="$db_id"

  # Presetting unprefixed env vars for '$DB_ID' DB based on prefixed globals,
  # if they exist (and if their values aren't empty).
  local v=''
  local db_var=''
  local prefixed_db_var=''

  u_db_vars_list

  for v in $db_vars_list; do
    case "$v" in 'ID')
      continue
    esac

    db_var="DB_$v"
    prefixed_db_var="${db_id}_${db_var}"
    u_str_uppercase "$prefixed_db_var" 'prefixed_db_var'

    if [[ -z "${!prefixed_db_var}" ]]; then
      continue
    fi

    if [[ -n "$CWT_DB_DEBUG" ]]; then
      echo "preset $db_var from $prefixed_db_var = '${!prefixed_db_var}'"
    fi

    export "$db_var=${!prefixed_db_var}"
  done

  # Give a chance to other extensions to preset non-readonly env vars, including
  # per STACK_VERSION and DB_ID.
  # make hook-debug s:db a:env_preset v:INSTANCE_TYPE PROVISION_USING STACK_VERSION DB_ID
  hook -s 'db' -a 'env_preset' -v 'INSTANCE_TYPE PROVISION_USING STACK_VERSION DB_ID'

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
  v=''
  db_var=''
  prefixed_db_var=''

  u_db_vars_list

  for v in $db_vars_list; do
    db_var="DB_$v"
    prefixed_db_var="${db_id}_${db_var}"
    u_str_uppercase "$prefixed_db_var" 'prefixed_db_var'
    export "$prefixed_db_var=${!db_var}"
  done

  # Allow bash aliases to be adapted to the currently active DB_ID.
  # @see cwt/extensions/mysql/cwt/alias.docker-compose.hook.sh
  hook -s 'cwt' -a 'alias' -v 'STACK_VERSION PROVISION_USING'
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
  # Debug.
  if [[ -n "$CWT_DB_DEBUG" ]]; then
    echo "u_db_unset"
  fi

  local v

  u_db_vars_list

  for v in $db_vars_list; do
    eval "unset DB_$v"
  done

  # Also need to reset the variable allowing to target a specific docker-compose
  # service depending on the currently active DB_ID.
  # @see cwt/extensions/mysql/cwt/alias.docker-compose.hook.sh
  if [[ -n "$dc_db_service_name" ]]; then
    unset dc_db_service_name
  fi
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
#   echo "${db_ids[@]}"
#
u_db_get_ids() {
  local db_id
  local multi_db_ids=''

  # Support multi-DB projects defined using the "append"-type global CWT_DB_IDS.
  # Defaults to CWT_APPS.
  if [[ -n "$CWT_DB_IDS" ]]; then
    for db_id in $CWT_DB_IDS; do
      u_array_add_once "$db_id" db_ids
    done
  elif [[ -n "$CWT_APPS" ]]; then
    for cwt_app in $CWT_APPS; do
      u_array_add_once "$cwt_app" db_ids
    done
  fi

  # Let extensions define their own additional DB_IDs.
  # They need to append values to the string :
  # @var multi_db_ids
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
      # Default DB will be loaded last, see below.
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
#
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
# for this functionality. It is necessary to use an extension that does. E.g. :
#
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
# @param 2 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
# @param 3 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
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
  local p_db_id="$2"
  local p_force_reload_flag="$3"

  local db_exists=''

  u_db_set "$p_db_id" "$p_force_reload_flag"

  # Debug.
  if [[ -n "$CWT_DB_DEBUG" ]]; then
    db_exists=true
    echo "u_db_exists $p_db_name $p_db_id"
    echo "  DB_HOST = $DB_HOST"
    echo "  DB_NAME = $DB_NAME"
  else
    u_hook_most_specific -s 'db' -a 'exists' -v 'DB_DRIVER DB_ID INSTANCE_TYPE'
  fi

  case "$db_exists" in true)
    return 0
  esac

  return 1
}

##
# Checks if given DB has already been flagged using local registry.
#
# It checks by default the flag to know if the DB is already setup (created).
# This allows to skip wait_for() calls for DB services started but with DBs not
# created yet.
#
# @see cwt/instance/setup.sh
# @see cwt/extensions/drush/instance/wait_for.docker-compose.hook.sh
# @see u_instance_registry_get() in cwt/instance/instance.inc.sh
#
# @param 1 String : the database ID ($DB_ID).
# @param 2 [optional] String : the flag. Defaults to 'is_already_setup'.
#
# @example
#   # Checks the default flag - to know if the DB is already setup (created).
#   if u_db_is_flagged 'my_db_id'; then
#     echo "Yes, 'my_db_id' was already setup."
#   else
#     echo "No."
#   fi
#
#   # Works for any flag. Negative check example :
#   if ! u_db_is_flagged 'my_db_id' 'is_locked'; then
#     echo "No, 'my_db_id' is not locked."
#   fi
#
u_db_is_flagged() {
  local reg_val

  u_db_get_flag_key $@
  u_instance_registry_get "$key"

  if [[ -n "$reg_val" ]]; then
    return 0
  fi

  return 1
}

##
# Flags given DB as already setup (created) using local registry.
#
# @see u_db_is_already_setup()
# @see cwt/instance/setup.sh
# @see cwt/extensions/drush/instance/wait_for.docker-compose.hook.sh
# @see u_instance_registry_set() in cwt/instance/instance.inc.sh
#
# @param 1 String : the database ID ($DB_ID).
# @param 2 [optional] String : the flag. Defaults to 'is_already_setup'.
#
# @example
#   u_db_mark_as_already_setup 'site'
#
u_db_flag() {
  u_db_get_flag_key $@
  u_instance_registry_set "$key" true
}

##
# Flags all defined DB_IDs using local registry.
#
# @see u_db_unflag()
#
# @param 1 [optional] String : the flag. Defaults to 'is_already_setup'.
#
# @example
#   u_db_flag_all
#
u_db_flag_all() {
  local db_id
  local db_ids=()

  u_db_get_ids

  if [[ -n "${db_ids[@]}" ]]; then
    for db_id in "${db_ids[@]}"; do
      u_db_flag "$db_id" "$1"
    done
  fi
}

##
# Unflags given DB as already setup (created) using local registry.
#
# @see u_db_is_already_setup()
# @see cwt/instance/setup.sh
# @see cwt/extensions/drush/instance/wait_for.docker-compose.hook.sh
# @see u_instance_registry_del() in cwt/instance/instance.inc.sh
#
# @param 1 String : the database ID ($DB_ID).
# @param 2 [optional] String : the flag. Defaults to 'is_already_setup'.
#
# @example
#   u_db_mark_as_already_setup 'site'
#
u_db_unflag() {
  u_db_get_flag_key $@
  u_instance_registry_del "$key"
}

##
# Unflags all defined DB_IDs using local registry.
#
# @see u_db_unflag()
#
# @param 1 [optional] String : the flag. Defaults to 'is_already_setup'.
#
# @example
#   u_db_unflag_all
#
u_db_unflag_all() {
  local db_id
  local db_ids=()

  u_db_get_ids

  if [[ -n "${db_ids[@]}" ]]; then
    for db_id in "${db_ids[@]}"; do
      u_db_unflag "$db_id" "$1"
    done
  fi
}

##
# Single source of truth for DB flags registry keys.
#
# Uses STACK_VERSION if set.
# This funtion writes its result to a variable subject to collision in calling
# scope :
#
# @var key
#
# @param 1 String : the database ID ($DB_ID).
# @param 2 [optional] String : the flag. Defaults to 'is_already_setup'.
#
# @example
#   u_db_get_flag_key 'site' 'is_already_setup'
#   echo "key = $key"
#
u_db_get_flag_key() {
  local p_db_id="$1"
  local p_flag="$2"

  if [[ -z "$p_flag" ]]; then
    p_flag='is_already_setup'
  fi

  key="db_${p_db_id}_flag_${p_flag}"

  if [[ -n "$STACK_VERSION" ]]; then
    key="db_${STACK_VERSION}_${p_db_id}_flag_${p_flag}"
  fi
}

##
# [abstract] Creates (+ sets up) new database.
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension that does. E.g. :
#
# @see cwt/extensions/mysql
# @see cwt/extensions/pgsql
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:db a:create v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:db a:create v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# @param 1 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   u_db_create
#
u_db_create() {
  local p_db_id="$1"
  local p_force_reload_flag="$2"

  u_db_set "$p_db_id" "$p_force_reload_flag"

  # Debug.
  if [[ -n "$CWT_DB_DEBUG" ]]; then
    echo "u_db_create $p_db_id"
    echo "  DB_HOST = $DB_HOST"
    echo "  DB_NAME = $DB_NAME"
  else
    u_hook_most_specific -s 'db' -a 'create' -v 'DB_DRIVER DB_ID INSTANCE_TYPE'
  fi
}

##
# [abstract] Destroys (deletes) a database.
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension that does. E.g. :
#
# @see cwt/extensions/mysql
# @see cwt/extensions/pgsql
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:db a:destroy v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:db a:destroy v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# @param 1 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   u_db_destroy
#   u_db_destroy 'custom_db_id'
#
u_db_destroy() {
  local p_db_id="$1"
  local p_force_reload_flag="$2"

  u_db_set "$p_db_id" "$p_force_reload_flag"

  # Debug.
  if [[ -n "$CWT_DB_DEBUG" ]]; then
    echo "u_db_destroy $p_db_id"
    echo "  DB_HOST = $DB_HOST"
    echo "  DB_NAME = $DB_NAME"
  else
    u_hook_most_specific -s 'db' -a 'destroy' -v 'DB_DRIVER DB_ID INSTANCE_TYPE'
  fi
}

##
# [abstract] Executes given file (containing any query) in given DB ID.
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension that does. E.g. :
#
# @see cwt/extensions/mysql
# @see cwt/extensions/pgsql
#
# Important notes : implementations of the hook -s 'db' -a 'dump' MUST use the
# following variable in calling scope as output path (resulting file) :
#
# @var db_dump_file
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:db a:exec v:DB_DRIVER DB_ID INSTANCE_TYPE PROVISION_USING
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:db a:exec v:DB_DRIVER DB_ID INSTANCE_TYPE PROVISION_USING
#
# @param 1 String : the dump file path.
# @param 2 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
# @param 3 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   u_db_exec 'path/to/dump/file.sql.tgz'
#
u_db_exec() {
  local p_dump_file_path="$1"
  local p_db_id="$2"
  local p_force_reload_flag="$3"

  local db_dump_dir
  local db_dump_file
  local leaf

  if [[ ! -f "$p_dump_file_path" ]]; then
    echo >&2
    echo "Error in u_db_exec() - $BASH_SOURCE line $LINENO: the DB dump file '$p_dump_file_path' is missing or inaccessible." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  u_db_set "$p_db_id" "$p_force_reload_flag"

  db_dump_file="$p_dump_file_path"

  # Debug.
  if [[ -n "$CWT_DB_DEBUG" ]]; then
    echo "u_db_exec $p_dump_file_path $p_db_id"
    echo "  DB_HOST = $DB_HOST"
    echo "  DB_NAME = $DB_NAME"
  fi

  # Query file may or may not be an archive. If it is, uncompress it.
  local extracted_file=''
  local compressed_file=''

  u_fs_extract_in_place "$db_dump_file"

  # Debug.
  if [[ -n "$CWT_DB_DEBUG" ]]; then
    echo "  extracted_file = $extracted_file"
  fi

  # When input file is an archive, we assume the uncompressed file will be
  # named exactly like the archive without its extension, e.g. :
  # - my-dump.sql.tgz -> my-dump.sql
  # - my-dump.sql.tar.gz -> my-dump.sql
  if [[ -f "$extracted_file" ]]; then
    echo "  Input file was compressed -> using extracted file '$extracted_file' as input."
    compressed_file="$db_dump_file"
    db_dump_file="$extracted_file"

    # Debug.
    if [[ -n "$CWT_DB_DEBUG" ]]; then
      echo "  compressed_file = $compressed_file"
      echo "  db_dump_file = $db_dump_file"
    fi
  elif [[ -n "$CWT_DB_DEBUG" ]]; then
    # Debug.
    echo "  db_dump_file = $db_dump_file"
  fi

  if [[ ! -f "$db_dump_file" ]]; then
    echo >&2
    echo "Error in u_db_exec() - $BASH_SOURCE line $LINENO: missing uncompressed dump file :" >&2
    echo "  $db_dump_file" >&2
    echo "  -> Aborting (2)." >&2
    echo >&2
    exit 2
  fi

  # Implementations MUST use var $db_dump_file as input path (source file).
  if [[ -z "$CWT_DB_DEBUG" ]]; then
    u_hook_most_specific -s 'db' -a 'exec' -v 'DB_DRIVER DB_ID INSTANCE_TYPE PROVISION_USING'
  fi

  # Remove uncompressed version of the dump when we're done.
  if [[ -f "$extracted_file" ]]; then
    echo "  Removing uncompressed file '$extracted_file' (now that it's restored)."

    rm "$extracted_file"

    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in u_db_exec() - $BASH_SOURCE line $LINENO: failed to remove uncompressed dump file '$db_dump_file'." >&2
      echo "-> Aborting (3)." >&2
      echo >&2
      exit 3
    fi
  fi
}

##
# Same as u_db_exec() but for running inline query.
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:db a:query v:DB_DRIVER DB_ID INSTANCE_TYPE PROVISION_USING
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:db a:query v:DB_DRIVER DB_ID INSTANCE_TYPE PROVISION_USING
#
# @param 1 String : the query.
# @param 2 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
# @param 3 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   u_db_query 'UPDATE users SET name = "foobar" WHERE email = "foo@bar.com";'
#
u_db_query() {
  local p_query="$1"
  local p_db_id="$2"
  local p_force_reload_flag="$3"

  u_db_set "$p_db_id" "$p_force_reload_flag"

  echo "Running query in $DB_DRIVER DB '$DB_NAME' ..."

  # Implementations MUST use var $p_query as input.
  if [[ -z "$CWT_DB_DEBUG" ]]; then
    u_hook_most_specific -s 'db' -a 'query' -v 'DB_DRIVER DB_ID INSTANCE_TYPE PROVISION_USING'
  else
    echo
    echo "[debug] would run query :"
    echo "$p_query"
    echo
  fi

  echo "Running query in $DB_DRIVER DB '$DB_NAME' : done."
  echo
}

##
# [abstract] Dumps database to a compressed (gz) dump file.
#
# This function does not implement the creation of the "raw" DB dump file, but
# it always compresses it after (appending ".gz" to given file path).
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension that does. E.g. :
#
# @see cwt/extensions/mysql
# @see cwt/extensions/pgsql
#
# Important notes : implementations of the hook -s 'db' -a 'dump' MUST use the
# following variable in calling scope as output path (resulting file) :
#
# @var db_dump_file
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:db a:dump v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:db a:dump v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# @param 1 String : the dump file path.
# @param 2 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
# @param 3 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   u_db_dump 'path/to/dump/file.sql'
#
u_db_dump() {
  local p_dump_file_path="$1"
  local p_db_id="$2"
  local p_force_reload_flag="$3"

  if [[ -z "$CWT_DB_DUMPS_BASE_PATH" ]]; then
    echo >&2
    echo "Error in u_db_dump() - $BASH_SOURCE line $LINENO: the required global 'CWT_DB_DUMPS_BASE_PATH' is undefined." >&2
    echo "Current instance must be (re)initialized with the 'db' extension enabled." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  local db_dump_dir
  local db_dump_file
  local db_dump_file_name

  u_db_set "$p_db_id" "$p_force_reload_flag"

  db_dump_file="$p_dump_file_path"
  db_dump_dir="${db_dump_file%/${db_dump_file##*/}}"

  # The "backup" action should only have to create a new file. If it already
  # exists, we consider it an error. This case should be explicitly dealt with
  # beforehand (e.g. existing file deleted or moved).
  if [[ -f "$db_dump_file" ]]; then
    echo >&2
    echo "Error in u_db_dump() - $BASH_SOURCE line $LINENO: destination file '$db_dump_file' already exists." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi

  if [[ ! -d "$db_dump_dir" ]]; then
    mkdir -p "$db_dump_dir"

    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in u_db_dump() - $BASH_SOURCE line $LINENO: failed to create new backup dir '$db_dump_dir'." >&2
      echo "-> Aborting (1)." >&2
      echo >&2
      exit 1
    fi
  fi

  # Implementations MUST use var $db_dump_file as output path (resulting file).
  if [[ -n "$CWT_DB_DEBUG" ]]; then
    echo "u_db_dump $p_dump_file_path $p_db_id"
    echo "  DB_HOST = $DB_HOST"
    echo "  DB_NAME = $DB_NAME"
  else
    u_hook_most_specific -s 'db' -a 'dump' -v 'DB_DRIVER DB_ID INSTANCE_TYPE'
  fi

  if [ ! -f "$db_dump_file" ]; then
    echo >&2
    echo "Error in u_db_dump() - $BASH_SOURCE line $LINENO: file '$db_dump_file' does not exist." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi

  # Compress & remove uncompressed dump file.
  db_dump_file_name="${db_dump_file##*/}"

  tar czf "$db_dump_file.gz" -C "$db_dump_dir" "$db_dump_file_name"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in u_db_dump() - $BASH_SOURCE line $LINENO: failed to compress dump file '$db_dump_file'." >&2
    echo "-> Aborting (3)." >&2
    echo >&2
    exit 3
  fi

  if [[ ! -f "$db_dump_file" ]]; then
    return
  fi

  rm "$db_dump_file"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in u_db_dump() - $BASH_SOURCE line $LINENO: failed to remove uncompressed dump file '$db_dump_file'." >&2
    echo "-> Aborting (4)." >&2
    echo >&2
    exit 4
  fi
}

##
# [abstract] Clears (empties) database.
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension that does. E.g. :
#
# @see cwt/extensions/mysql
# @see cwt/extensions/pgsql
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:db a:clear v:DB_DRIVER DB_ID INSTANCE_TYPE
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:db a:clear v:DB_DRIVER DB_ID INSTANCE_TYPE
#
# @param 1 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   u_db_clear
#
u_db_clear() {
  local p_db_id="$1"
  local p_force_reload_flag="$2"

  u_db_set "$p_db_id" "$p_force_reload_flag"

  # Only attempt to clear if DB exists.
  if ! u_db_exists "$DB_NAME" "$p_db_id"; then
    echo "Notice: DB name '$DB_NAME' does not appear to exist -> skip clearing."
    return;
  fi

  # Debug.
  if [[ -n "$CWT_DB_DEBUG" ]]; then
    echo "u_db_clear $p_db_id"
    echo "  DB_HOST = $DB_HOST"
    echo "  DB_NAME = $DB_NAME"
  else
    u_hook_most_specific -s 'db' -a 'clear' -v 'DB_DRIVER DB_ID INSTANCE_TYPE'
  fi
}

##
# Empties database + imports given dump file.
#
# @param 1 String : the dump file path.
# @param 2 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
# @param 3 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   u_db_restore 'path/to/dump/file.sql'
#   u_db_restore 'path/to/dump/file.sql' 'my_custom_db_id'
#
u_db_restore() {
  local p_dump_file_path="$1"
  local p_db_id="$2"
  local p_force_reload_flag="$3"

  if [[ ! -f "$p_dump_file_path" ]]; then
    echo >&2
    echo "Error in u_db_restore() - $BASH_SOURCE line $LINENO: the DB dump file '$p_dump_file_path' is missing or inaccessible." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  u_db_clear "$p_db_id" "$p_force_reload_flag"
  u_db_exec "$p_dump_file_path" "$p_db_id" "$p_force_reload_flag"
}

##
# Empties database + imports the last (= most recent) dump file available.
#
# @see u_fs_get_most_recent()
# @requires globals CWT_DB_DUMPS_BASE_PATH in calling scope.
#
# @param 1 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
# @param 2 [optional] String : subfolder in DB dumps dir.
#   Defaults to 'local'.
# @param 3 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   u_db_restore_last
#
u_db_restore_last() {
  local p_db_id="$1"
  local p_subdir="$2"
  local p_force_reload_flag="$3"

  if [[ -z "$CWT_DB_DUMPS_BASE_PATH" ]]; then
    echo >&2
    echo "Error in u_db_restore_last() - $BASH_SOURCE line $LINENO: the required global 'CWT_DB_DUMPS_BASE_PATH' is undefined." >&2
    echo "Current instance must be (re)initialized with the 'db' extension enabled." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  if [[ ! -d "$CWT_DB_DUMPS_BASE_PATH" ]]; then
    echo >&2
    echo "Error in u_db_restore_last() - $BASH_SOURCE line $LINENO: the dir $CWT_DB_DUMPS_BASE_PATH does not exist." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi

  if [[ -z "$p_db_id" ]]; then
    p_db_id='default'
  fi

  if [[ -z "$p_subdir" ]]; then
    p_subdir='local'
  fi

  u_db_restore \
    "$(u_fs_get_most_recent $CWT_DB_DUMPS_BASE_PATH/$p_subdir/$p_db_id)" \
    "$p_db_id" \
    "$p_force_reload_flag"
}

##
# Routine local DB dump (backup).
#
# The dump file path will be determined by the following globals :
#   - CWT_DB_DUMPS_BASE_PATH
#   - CWT_DB_DUMPS_LOCAL_PATTERN
#
# @see cwt/extensions/db/global.vars.sh
#
# This function writes its result to a variable subject to collision in calling
# scope :
#
# @var routine_dump_file
#
# @param 1 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   u_db_routine_backup
#   echo "routine_dump_file = $routine_dump_file"
#
#   # Resulting dump file path example :
#   # data/db-dumps/local/default/2024-08-08.17-25-29_local-default.paul.sql
#
u_db_routine_backup() {
  local p_db_id="$1"
  local p_force_reload_flag="$2"

  if [[ -z "$CWT_DB_DUMPS_BASE_PATH" ]]; then
    echo >&2
    echo "Error in u_db_routine_backup() - $BASH_SOURCE line $LINENO: the required global 'CWT_DB_DUMPS_BASE_PATH' is undefined." >&2
    echo "Current instance must be (re)initialized with the 'db' extension enabled." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  if [[ -z "$CWT_DB_DUMPS_LOCAL_PATTERN" ]]; then
    echo >&2
    echo "Error in u_db_routine_backup() - $BASH_SOURCE line $LINENO: the required global 'CWT_DB_DUMPS_LOCAL_PATTERN' is undefined." >&2
    echo "Current instance must be (re)initialized with the 'db' extension enabled." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi

  u_db_set "$p_db_id" "$p_force_reload_flag"

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

  # Init var used in the pattern.
  # @see cwt/extensions/db/global.vars.sh
  # @see u_str_convert_tokens() in
  local DUMP_FILE_EXTENSION="$db_backup_file_ext"

  u_str_convert_tokens CWT_DB_DUMPS_LOCAL_PATTERN 'db_routine_new_backup_file'

  # Debug.
  # echo "db_routine_new_backup_file = '$db_routine_new_backup_file'"

  u_db_dump \
    "$CWT_DB_DUMPS_BASE_PATH/local/$DB_ID/$db_routine_new_backup_file" \
    "$p_db_id" \
    "$p_force_reload_flag"

  # Some tasks need the generated dump file path.
  routine_dump_file="${db_routine_new_backup_file}.gz"
}

##
# Gets local instance DB dump filepath.
#
# Optionally creates a new routine dump first.
#
# @param 1 [optional] String : Pass 'new' to create immediately a new routine
#   dump and return its file path. Pass 'last' to return the most recent dump
#   file. Any other value is a "find" file name filter that will return a single
#   matching dump (the most recent in case there are several matches).
#   Defaults to 'last'.
# @param 2 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
# @param 3 [optional] String : subfolder in DB dumps dir.
#   Defaults to 'local'.
# @param 4 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
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
  local p_subdir="$3"
  local p_force_reload_flag="$4"

  if [[ -z "$p_option" ]]; then
    p_option='last'
  fi

  if [[ -z "$p_db_id" ]]; then
    p_db_id='default'
  fi

  if [[ -z "$p_subdir" ]]; then
    p_subdir='local'
  fi

  local dump_to_return

  case "$p_option" in
    'last')
      dump_to_return="$(u_fs_get_most_recent "$CWT_DB_DUMPS_BASE_PATH/$p_subdir/$p_db_id")"
      ;;

    # The 'new' option means create immediately a new routine dump and return
    # its file path.
    'new')
      u_db_routine_backup "$p_db_id" "$p_force_reload_flag"
      dump_to_return="$routine_dump_file"
      ;;

    # Any other value is a "find" file name filter.
    *)
      dump_to_return="$(u_fs_get_most_recent "$CWT_DB_DUMPS_BASE_PATH/$p_subdir/$p_db_id" "$p_option")"
      ;;
  esac

  if [[ -f "$dump_to_return" ]]; then
    echo "$dump_to_return"
  fi
}

##
# Setup a new database (create + import initial dump).
#
# @param 1 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   u_db_setup
#   u_db_setup 'custom_db_id'
#
u_db_setup() {
  local p_db_id="$1"
  local p_force_reload_flag="$2"

  u_db_set "$p_db_id" "$p_force_reload_flag"

  # Debug.
  if [[ -n "$CWT_DB_DEBUG" ]]; then
    echo
    echo "u_db_setup $p_db_id"
    echo "  DB_HOST = $DB_HOST"
    echo "  DB_NAME = $DB_NAME"
  fi

  # Only create the database if it does not already exist.
  if u_db_exists "$DB_NAME" "$p_db_id"; then
    echo "The $DB_ID database ('$DB_NAME') exists already."
  else
    u_db_create "$DB_ID" "$p_force_reload_flag"
  fi

  # Only move on to the initial DB import if configured to do so.
  case "$CWT_DB_INITIAL_IMPORT" in true)
    u_db_restore_any "$DB_ID"
  esac

  # Flag the DB as already setup.
  if u_db_exists "$DB_NAME" "$p_db_id"; then
    u_db_flag "$DB_ID"
  else
    u_db_unflag "$DB_ID"

    echo >&2
    echo "Error in u_db_setup() - $BASH_SOURCE line $LINENO: the $DB_ID database '$DB_NAME' was not created." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi
}

##
# Restores any dump found that matches given DB ID.
#
# Attempts to download a remote dump corresponding to DB ID if none is found.
#
# The dump file can be in any subfolder, as long as it corresponds to the
# corrrect DB ID.
#
# @param 1 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   u_db_restore_any
#   u_db_restore_any 'custom_db_id'
#
u_db_restore_any() {
  local p_db_id="$1"
  local p_force_reload_flag="$2"

  u_db_set "$p_db_id" "$p_force_reload_flag"

  # Debug.
  if [[ -n "$CWT_DB_DEBUG" ]]; then
    echo "u_db_restore_any $p_db_id"
    echo "  DB_HOST = $DB_HOST"
    echo "  DB_NAME = $DB_NAME"
  fi

  # The initial dump file can be in any subfolder, as long as it corresponds to
  # the corrrect DB ID. We'll try the following folders, and use the first dump
  # file found.
  local initial_dump_file=''
  local lookup_subdir
  local lookup_subdirs=()

  # If the "remote" CWT extension is enabled, look for dumps previously
  # downloaded. We can check if extension is enabled by verifying that the
  # function u_remote_get_instances() is defined.
  # @see cwt/extensions/remote/remote.inc.sh
  local instance_id
  local instance_ids=()

  if type u_remote_get_instances >/dev/null 2>&1 ; then
    u_remote_get_instances
  fi

  if [[ -n "${instance_ids[@]}" ]]; then
    for instance_id in "${instance_ids[@]}"; do
      lookup_subdirs+=("$instance_id")
    done
  fi

  # Also look into local dumps.
  lookup_subdirs+=('local')

  # The 'prod' remote (if it exists) dumps take priority.
  if [[ -d "$CWT_DB_DUMPS_BASE_PATH/prod/$DB_ID" ]]; then
    initial_dump_file="$(u_fs_get_most_recent "$CWT_DB_DUMPS_BASE_PATH/prod/$DB_ID" '*.gz')"
  fi

  if [[ ! -f "$initial_dump_file" ]]; then
    for lookup_subdir in "${lookup_subdirs[@]}"; do
      if [[ ! -d "$CWT_DB_DUMPS_BASE_PATH/$lookup_subdir/$DB_ID" ]]; then
        continue
      fi

      initial_dump_file="$(u_fs_get_most_recent "$CWT_DB_DUMPS_BASE_PATH/$lookup_subdir/$DB_ID" '*.gz')"

      if [[ -f "$initial_dump_file" ]]; then
        break
      fi
    done
  fi

  # If there is no local DB dump found, and if the "remote_db" extension exists,
  # attempt to fetch latest remote dump file for given DB ID.
  if [[ ! -f "$initial_dump_file" ]] && [[ -n "${instance_ids[@]}" ]]; then
    for instance_id in "${instance_ids[@]}"; do

      # TODO [evol] do not attempt to download dump from remotes that do not
      # host given DB_ID.

      # Also this implies dependency on the remote_db extension, not always
      # enabled.

      # Debug.
      if [[ -n "$CWT_DB_DEBUG" ]]; then
        echo "  [debug] would download $DB_ID DB from $instance_id"
      else
        cwt/extensions/remote_db/remote/db_download.sh "$instance_id" "$DB_ID"
      fi

      if [[ ! -d "$CWT_DB_DUMPS_BASE_PATH/$instance_id/$DB_ID" ]]; then
        continue
      fi

      initial_dump_file="$(u_fs_get_most_recent "$CWT_DB_DUMPS_BASE_PATH/$instance_id/$DB_ID" '*.gz')"

      if [[ -f "$initial_dump_file" ]]; then
        break
      fi
    done
  fi

  if [[ ! -f "$initial_dump_file" ]]; then
    echo >&2
    echo "Error in u_db_restore_any() - $BASH_SOURCE line $LINENO: no dump file was found." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  echo "Importing $DB_ID DB dump file '$initial_dump_file' ..."

  u_db_restore "$initial_dump_file" "$DB_ID"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: failed to import initial DB dump file '$initial_dump_file'." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  echo "Importing $DB_ID DB dump file '$initial_dump_file' : done."
}
