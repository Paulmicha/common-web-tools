#!/bin/bash

##
# GLobals-related utility functions.
#
# See cwt/env/README.md
#
# This file is dynamically loaded.
# @see cwt/bash_utils.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Reads value by key for 'append' globals declaring 'to' keys.
#
# @example
#   global REMOTE_INSTANCES_CMDS "[append]='/path/to/remote/instance/docroot' [to]=PROJECT_DOCROOT"
#   u_global_read_key 'PROJECT_DOCROOT' "$REMOTE_INSTANCES_CMDS"
#   # -> result : "/path/to/remote/instance/docroot"
#
u_global_read_key() {
  local p_key="$1"
  local p_sub_keyed_str="$2"

  local prefix_delimiter="$(u_cwt_common_val globals-key-prefix)"
  local tmp_space_placeholder="$(u_cwt_common_val globals-tmp-space-placeholder)"

  local sub_keyed_str_item=''
  local sub_keyed_str_key=''
  local sub_keyed_str_val=''

  local output=''

  for sub_keyed_str_item in $p_sub_keyed_str; do

    # Match last occurence of key from the end of the string.
    # See http://wiki.bash-hackers.org/syntax/pe#from_the_end
    sub_keyed_str_key="${sub_keyed_str_item%%$prefix_delimiter*}"

    if [[ "$sub_keyed_str_key" == "$p_key" ]]; then
      # Match 1st occurence of key from the beginning of the string.
      # See http://wiki.bash-hackers.org/syntax/pe#from_the_beginning
      sub_keyed_str_val="${sub_keyed_str_item#*$prefix_delimiter}"
      output+="$(u_str_replace "$tmp_space_placeholder" ' ' "$sub_keyed_str_val") "
    fi
  done

  echo $(u_string_trim "$output")
}

##
# Executes given callback function for all env vars discovered so far.
#
# @requires the following globals in calling scope (main shell) :
# - $GLOBALS
# - $GLOBALS_UNIQUE_NAMES
#
# @see cwt/stack/init/aggregate_env_vars.sh
#
# @example
#   u_global_foreach u_global_assign_value
#
u_global_foreach() {
  local p_callback="$1"
  local globals_arr
  local global_name

  for global_name in ${GLOBALS['.sorting']}; do
    u_str_split1 globals_arr $global_name '|'
    global_name="${globals_arr[1]}"
    $p_callback $global_name
  done
}

##
# Assigns arg or default value to given global env var.
#
# Unless "-y" argument was used in cwt/stack/init.sh call, this will also prompt
# before using default value fallback.
#
# @param 1 String : global variable name.
#
# @requires the following globals in calling scope :
# - $P_YES
# - $GLOBALS
# - $P_MY_VAR_NAME (replacing 'MY_VAR_NAME' with the actual var name)
#
# @see global()
# @see cwt/stack/init/get_args.sh
# @see cwt/stack/init/aggregate_env_vars.sh
#
# @example
#   u_global_assign_value 'MY_VAR_NAME'
#
u_global_assign_value() {
  local p_var="$1"
  local multi_values=''

  eval "export $p_var"

  eval "local arg_val=\$P_${p_var}"
  local default_val="${GLOBALS[$p_var|default]}"

  if [[ -n "$arg_val" ]]; then
    eval "$p_var='$arg_val'"

  # Non-configurable vars.
  elif [[ "${GLOBALS[$p_var|no_prompt]}" == 1 ]]; then
    eval "$p_var='${GLOBALS[$p_var|value]}'"

  # List or "pile" of values (space-separated string).
  elif [[ -n "${GLOBALS[$p_var|values]}" ]]; then
    multi_values=$(u_string_trim "${GLOBALS[$p_var|values]}")
    eval "$p_var='$multi_values'"

  # Implement several entries per global using the 'to' key (contains "subkey").
  # Syntax : space-separated string using '.' as prefix delimiter, i.e :
  # MY_VAR='key1.value key2.another_value'
  # Workaround : values cannot contain spaces, so they are replaced by an
  #   arbitrary value (unlikely to collide) for backward-conversion during read.
  # @see u_global_read_key()
  elif [[ -n "${GLOBALS[$p_var|tos]}" ]]; then
    local sub_val
    local sub_key
    local sub_keys=$(u_string_trim "${GLOBALS[$p_var|tos]}")
    local prefix_delimiter="$(u_cwt_common_val globals-key-prefix)"

    for sub_key in $sub_keys; do
      if [[ -n "${GLOBALS[$p_var|$sub_key]}" ]]; then
        sub_val=$(u_string_trim "${GLOBALS[$p_var|$sub_key]}")
        sub_val="$(u_str_replace ' ' "$(u_cwt_common_val globals-tmp-space-placeholder)" "$sub_val")"
        multi_values+="${sub_key}${prefix_delimiter}${sub_val} "
      fi
    done

    multi_values="$(u_string_trim "$multi_values")"
    eval "$p_var='$multi_values'"

  # Skippable default value assignment.
  elif [[ $P_YES == 0 ]]; then
    echo
    if [[ -n "$default_val" ]]; then
      echo "Enter $p_var value,"
      eval "read -p \"or leave blank to use '$default_val' : \" $p_var"
    else
      eval "read -p \"Enter $p_var value : \" $p_var"
    fi
  fi

  # Assign default value fallback if the value is empty (e.g. may have been the
  # result of entering empty value in prompt).
  local empty_test=$(eval "echo \"\$$p_var\"")
  if [[ (-z "$empty_test") && (-n "$default_val") ]]; then
    eval "$p_var='$default_val'"
  fi

  # Once prompt has been made, prevent repeated calls for this var (recursion).
  # @see cwt/stack/init/aggregate_env_vars.sh
  # Except for 'append' vars (multiple values must pile-up on each call).
  if [[ ("${GLOBALS[$p_var|no_prompt]}" != 1) && (-z "$multi_values") ]]; then
    GLOBALS[$p_var|no_prompt]=1
    GLOBALS[$p_var|value]=$(eval "echo \"\$$p_var\"")
  fi
}

##
# Adds new variable in $GLOBALS.
#
# Increments a shared counter to maintain order, because some variables may depend
# on each other.
#
# @param 1 String : global variable name.
# @param 2 [optional] String : non-configurable value or key/value syntax (see
#   examples below)
# @param 3 Integer : flag to prevent automatic export.
#
# @requires the following globals in calling scope (main shell) :
# - $GLOBALS
# - $GLOBALS_COUNT
# - $GLOBALS_UNIQUE_NAMES
# - $GLOBALS_UNIQUE_KEYS
#
# @see u_global_assign_value()
# @see cwt/stack/init.sh
# @see cwt/stack/init/aggregate_env_vars.sh
#
# For better readability in env includes files, we exceptionally name that
# function without following the usual convention.
#
# @examples (write)
#   global MY_VAR_NAME
#   global MY_VAR_NAME "Simple string declaration (non-configurable / no prompt to customize during init)"
#   global MY_VAR_NAME2 "[default]=test"
#
#   # Custom keys may be used, provided they don't clash with the following keys
#   # already used internally by CWT :
#   # - 'default'
#   # - 'value'
#   # - 'values'
#   # - 'no_prompt'
#   # - 'append'
#   # - 'if-VAR_NAME'
#   global MY_VAR_NAME3 "[key]=value [key2]='value 2' [key3]='$(my_callback_function)'"
#
# @examples (append)
#   # Notice there cannot be any space inside each value.
#   global MY_MULTI_VALUE_VAR "[append]=multiple"
#   global MY_MULTI_VALUE_VAR "[append]=declarations"
#   global MY_MULTI_VALUE_VAR "[append]=will-be"
#   global MY_MULTI_VALUE_VAR "[append]=appended/to"
#   global MY_MULTI_VALUE_VAR "[append]=a_SPACE_separated_string"
#   # Example read :
#   for val in $MY_MULTI_VALUE_VAR; do
#     echo "MY_MULTI_VALUE_VAR value : $val"
#   done
#
# @examples (condition)
#   global MY_VAR "hello value"
#   global MY_COND_VAR_NOMATCH "[if-MY_VAR]=test [default]=foo"
#   global MY_COND_VAR_MATCH "[if-MY_VAR]='hello value' [default]=bar"
#   # To verify (should only output MY_COND_VAR_MATCH) :
#   u_global_foreach u_global_assign_value
#   u_global_debug
#
# @example (read)
#   u_global_debug
#
global() {
  local p_var_name="$1"
  local p_values="$2"
  local p_prevent_export="$3"

  if [[ -n "$p_values" ]]; then

    # If the value does not begin with '[', assume the var non-configurable.
    if [[ "${p_values:0:1}" != '[' ]]; then
      GLOBALS["${p_var_name}|value"]="$p_values"
      GLOBALS["${p_var_name}|no_prompt"]=1

    # Key/value store system.
    else
      local declaration_arr

      # Transform input string to associative array.
      eval "declare -A declaration_arr=( $p_values )"

      for key in "${!declaration_arr[@]}"; do
        u_array_add_once "$key" GLOBALS_UNIQUE_KEYS

        case "$key" in

          # Handles conditional declarations. Prevents declaring the variable
          # altogether if the depending variable's value does not match the one
          # provided (matching using operator provided as a prefix).
          if-*|notif-*)
            local depending_var="${key:3}"
            local depending_value=$(eval "echo \"\$$depending_var\"")
            case "$key" in
              notif-*)
                if [[ "$depending_value" == "${declaration_arr[$key]}" ]]; then
                  return 0
                fi
              ;;
              if-*)
                if [[ "$depending_value" != "${declaration_arr[$key]}" ]]; then
                  return 0
                fi
              ;;
            esac
          ;;

          # Appends multiple values to the same var. Allow globals to be
          # declared multiple times to add values (space-separated string).
          append)
            # Ability to scope values in different "piles" using the 'to' key.
            # Defaults to 'values'.
            local append_to='values'

            if [[ -n "${declaration_arr[to]}" ]]; then
              append_to="${declaration_arr[to]}"
            fi

            if [[ -n "${GLOBALS[$p_var_name|values]}" ]]; then
              GLOBALS["${p_var_name}|$append_to"]+=" ${declaration_arr[$key]}"
            else
              GLOBALS["${p_var_name}|$append_to"]="${declaration_arr[$key]}"
            fi
          ;;

          # For 'append' using the 'to' key, we need to easily fetch all "piles"
          # (all values that were used in 'to').
          to)
            if [[ -n "${GLOBALS[$p_var_name|tos]}" ]]; then
              GLOBALS["${p_var_name}|tos"]+=" ${declaration_arr[$key]}"
            else
              GLOBALS["${p_var_name}|tos"]="${declaration_arr[$key]}"
            fi
          ;;

          # Default.
          *)
            GLOBALS["${p_var_name}|${key}"]="${declaration_arr[$key]}"
          ;;
        esac
      done
    fi
  fi

  # These globals allow dynamic handling of args and default values.
  if ! u_in_array $p_var_name GLOBALS_UNIQUE_NAMES; then
    ((++GLOBALS_COUNT))
    GLOBALS_UNIQUE_NAMES+=($p_var_name)

    # This will be used to sort the array when complete.
    # See https://stackoverflow.com/a/39543809
    GLOBALS['.sorting']+=" ${GLOBALS_COUNT}|${p_var_name} "
  fi

  # Immediately attempt to export that variable unless explicitly prevented.
  # This allows conditional declarations in them (i.e. useful for settings that
  # need to adapt/react to each other).
  if [[ -z "$p_prevent_export" ]]; then
    u_global_assign_value "$p_var_name"
  fi
}

##
# [debug] Prints current environment globals and their associated data.
#
# @see global()
#
u_global_debug() {
  local global_name
  local globals_arr
  local key
  local val

  echo
  echo "Defined globals :"
  echo

  for global_name in ${GLOBALS['.sorting']}; do
    u_str_split1 globals_arr $global_name '|'
    global_name="${globals_arr[1]}"

    eval "[[ -z \"\$$global_name\" ]] && echo \"$global_name\" \(empty\)";
    eval "[[ -n \"\$$global_name\" ]] && echo \"$global_name = \$$global_name\"";

    for key in ${GLOBALS_UNIQUE_KEYS[@]}; do
      val="${GLOBALS[$global_name|$key]}"
      if [[ -n "$val" ]]; then
        echo "  - ${key} = ${GLOBALS[${global_name}|${key}]}";
      fi
    done
  done
  echo
}

##
# Gets env settings includes lookup paths.
#
# @param 1 [optional] String :
#   $PROJECT_STACK override (should exist in calling scope).
# @param 2 [optional] String :
#   $PROVISION_USING override (should exist in calling scope).
#
# @requires the following globals in calling scope :
# - $APP
# - $APP_VERSION
# - $STACK_SERVICES
# - $STACK_PRESETS
# - $PROVISION_USING
#
# @see u_stack_get_specs()
# @see cwt/stack/init/aggregate_env_vars.sh
#
# @example
#   u_global_get_includes_lookup_paths 'drupal-7--p-opigno,solr,memcached' 'docker-compose-3'
#   for env_model in "${GLOBALS_INCLUDES_PATHS[@]}"; do
#     echo "$env_model"
#   done
#
u_global_get_includes_lookup_paths() {
  local p_project_stack="$1"
  local p_provision_using="$2"

  export GLOBALS_INCLUDES_PATHS

  local stack
  if [[ -n "$p_project_stack" ]]; then
    stack="$p_project_stack"
  else
    stack="$PROJECT_STACK"
  fi

  local provisioning
  if [[ -n "$p_provision_using" ]]; then
    provisioning="$p_provision_using"
  else
    provisioning="$PROVISION_USING"
  fi

  GLOBALS_INCLUDES_PATHS=()

  if [[ -n "$APP_VERSION" ]]; then
    local app_v
    local app_path=''
    local app_version_arr=()
    u_str_split1 app_version_arr "$APP_VERSION" '.'
  fi

  # Provisioning-related includes.
  local p
  local p_arr=()
  u_instance_item_split_version p_arr "$PROVISION_USING"
  if [[ -n "${p_arr[1]}" ]]; then
    local p_v
    local p_path="cwt/provision/${p_arr[0]}"
    local p_version_arr=()
    u_array_add_once "$p_path/vars.sh" GLOBALS_INCLUDES_PATHS
    u_str_split1 p_version_arr "${p_arr[1]}" '.'
    for p_v in "${p_version_arr[@]}"; do
      p_path+="/$p_v"
      u_array_add_once "$p_path/vars.sh" GLOBALS_INCLUDES_PATHS
    done
  else
    u_array_add_once "cwt/provision/${PROVISION_USING}/vars.sh" GLOBALS_INCLUDES_PATHS
  fi

  local ss_arr=()
  for stack_service in "${STACK_SERVICES[@]}"; do
    u_instance_item_split_version ss_arr "$stack_service"
    if [[ -n "${ss_arr[1]}" ]]; then
      u_global_get_includes_lookup_version "cwt/provision/${ss_arr[0]}" "${ss_arr[1]}" true
    else
      u_array_add_once "cwt/provision/${stack_service}/vars.sh" GLOBALS_INCLUDES_PATHS
      u_autoload_add_lookup_level "cwt/provision/${stack_service}/" 'vars.sh' "$PROVISION_USING" GLOBALS_INCLUDES_PATHS
    fi
  done

  # Presets-related includes.
  local sp_arr=()
  local sp_type
  local sp_types='provision app custom'

  for stack_preset in "${STACK_PRESETS[@]}"; do
    u_instance_item_split_version sp_arr "$stack_preset"
    if [[ -n "${sp_arr[1]}" ]]; then
      for sp_type in $sp_types; do
        u_global_get_includes_lookup_version "cwt/$sp_type/presets/${sp_arr[0]}" "${sp_arr[1]}" true
      done
    else
      for sp_type in $sp_types; do
        u_array_add_once "cwt/$sp_type/presets/${stack_preset}/vars.sh" GLOBALS_INCLUDES_PATHS
        u_autoload_add_lookup_level "cwt/$sp_type/presets/${stack_preset}/" 'vars.sh' "$PROVISION_USING" GLOBALS_INCLUDES_PATHS
      done
    fi
  done

  # App-related includes.
  u_array_add_once "cwt/app/${APP}/env.vars.sh" GLOBALS_INCLUDES_PATHS
  u_autoload_add_lookup_level "cwt/app/${APP}/env." 'vars.sh' "$PROVISION_USING" GLOBALS_INCLUDES_PATHS

  if [[ -n "$APP_VERSION" ]]; then
    app_path="cwt/app/$APP"
    for app_v in "${app_version_arr[@]}"; do
      app_path+="/$app_v"
      u_array_add_once "$app_path/env.vars.sh" GLOBALS_INCLUDES_PATHS
      u_autoload_add_lookup_level "$app_path/env." 'vars.sh' "$PROVISION_USING" GLOBALS_INCLUDES_PATHS
    done
  fi
}

##
# Appends version number lookups.
#
# @see u_global_get_includes_lookup_paths()
#
u_global_get_includes_lookup_version() {
  local p_prefix="$1"
  local p_version="$2"
  local p_prepend_raw="$3"

  local v
  local path="$p_prefix"
  local version_arr=()

  if [[ "$p_prepend_raw" == true ]]; then
    u_array_add_once "$path/vars.sh" GLOBALS_INCLUDES_PATHS
    u_autoload_add_lookup_level "$path/" 'vars.sh' "$PROVISION_USING" GLOBALS_INCLUDES_PATHS
  fi

  u_str_split1 version_arr "$p_version" '.'
  for v in "${version_arr[@]}"; do
    path+="/$v"

    if [[ "$p_prepend_raw" == true ]]; then
      u_array_add_once "$path/vars.sh" GLOBALS_INCLUDES_PATHS
    fi

    u_autoload_add_lookup_level "$path/" 'vars.sh' "$PROVISION_USING" GLOBALS_INCLUDES_PATHS
  done
}

##
# Separates an env item name from its version number.
#
# Follows a simplistic syntax : inputting 'app_test_a-name-test-1.2'
# -> output ['app_test_a-name-test', '1.2']
#
# @param 1 The variable name that will contain the array (in calling scope).
# @param 2 String to separate.
#
# @example
#   u_instance_item_split_version env_item_arr 'app_test_a-name-test-1.2'
#   for item_part in "${env_item_arr[@]}"; do
#     echo "$item_part"
#   done
#
u_instance_item_split_version() {
  local p_var_name="$1"
  local p_str="$2"

  eval "${p_var_name}=()"

  local version_part="${p_str##*-}"

  # If last part doesn't match only numbers and dots, just return [$p_str].
  if [[ ! "$version_part" =~ [0-9.]+$ ]]; then
    eval "${p_var_name}+=(\"$p_str\")"
    return
  fi

  local name_part="${p_str%-*}"

  if [[ -n "$name_part" ]]; then
    eval "${p_var_name}+=(\"$name_part\")"
  fi

  if [[ (-n "$version_part") && ("$version_part" != "$name_part") ]]; then
    eval "${p_var_name}+=(\"$version_part\")"
  fi
}

##
# Gets default value for this project instance's domain.
#
# Some projects may have DNS-dependant features to test locally, so we
# provide a default one based on project docroot dirname. In these cases, the
# necessary domains must be added to the device's hosts file (usually located
# in /etc/hosts or C:\Windows\System32\drivers\etc\hosts). Alternatives also
# exist to achieve this.
#
# The generated domain uses 'io' TLD in order to avoid trigger searches from
# some browsers address bars (like Chrome's).
#
u_get_instance_domain() {
  local lh="$(u_get_localhost_ip)"

  if [[ -z "$lh" ]]; then
    lh='local'
  fi

  if [[ $lh == "192.168."* ]]; then
    lh="${lh//192.168./lan-}"
  else
    lh="host-${lh}"
  fi

  echo "${PWD##*/}.${lh//./-}.io"
}
