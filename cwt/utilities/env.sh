#!/bin/bash

##
# Env (settings) related utility functions.
#
# See cwt/env/README.md
#
# This file is dynamically loaded.
# @see cwt/bash_utils.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Executes given callback function for all env vars discovered so far.
#
# @requires the following globals in calling scope (main shell) :
# - $ENV_VARS
# - $ENV_VARS_UNIQUE_NAMES
#
# @see cwt/stack/init/aggregate_env_vars.sh
#
# @example
#   u_exec_foreach_env_vars u_assign_env_value
#
u_exec_foreach_env_vars() {
  local p_callback="$1"
  local env_arr
  local env_var_name

  for env_var_name in ${ENV_VARS['.sorting']}; do
    u_str_split1 env_arr $env_var_name '|'
    env_var_name="${env_arr[1]}"
    $p_callback $env_var_name
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
# - $ENV_VARS
# - $P_MY_VAR_NAME (replacing 'MY_VAR_NAME' with the actual var name)
#
# @see cwt/stack/init/get_args.sh
# @see cwt/stack/init/aggregate_env_vars.sh
#
# @example
#   u_assign_env_value 'MY_VAR_NAME'
#
u_assign_env_value() {
  local p_var="$1"
  local multi_values=''

  eval "export $p_var"

  eval "local arg_val=\$P_${p_var}"
  local default_val="${ENV_VARS[$p_var|default]}"

  if [[ -n "$arg_val" ]]; then
    eval "$p_var='$arg_val'"

  # Handle non-configurable vars.
  elif [[ "${ENV_VARS[$p_var|no_prompt]}" == 1 ]]; then
    eval "$p_var='${ENV_VARS[$p_var|value]}'"
  elif [[ -n "${ENV_VARS[$p_var|values]}" ]]; then
    multi_values=$(u_string_trim "${ENV_VARS[$p_var|values]}")
    eval "$p_var='$multi_values'"

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
  if [[ ("${ENV_VARS[$p_var|no_prompt]}" != 1) && (-z "$multi_values") ]]; then
    ENV_VARS[$p_var|no_prompt]=1
    ENV_VARS[$p_var|value]=$(eval "echo \"\$$p_var\"")
  fi
}

##
# Adds new variable in $ENV_VARS.
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
# - $ENV_VARS
# - $ENV_VARS_COUNT
# - $ENV_VARS_UNIQUE_NAMES
# - $ENV_VARS_UNIQUE_KEYS
#
# @see cwt/stack/init.sh
# @see cwt/stack/init/aggregate_env_vars.sh
#
# For better readability in env models files, we exceptionally name that
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
#   u_exec_foreach_env_vars u_assign_env_value
#   u_print_env
#
# @example (read)
#   u_print_env
#
global() {
  local p_var_name="$1"
  local p_values="$2"
  local p_prevent_export="$3"

  if [[ -n "$p_values" ]]; then

    # If the value does not begin with '[', assume the var non-configurable.
    if [[ "${p_values:0:1}" != '[' ]]; then
      ENV_VARS["${p_var_name}|value"]="$p_values"
      ENV_VARS["${p_var_name}|no_prompt"]=1

    # Key/value store system.
    else
      local values_arr
      eval "declare -A values_arr=( $p_values )"
      for key in "${!values_arr[@]}"; do
        u_array_add_once "$key" ENV_VARS_UNIQUE_KEYS
        case "$key" in

          # Handles conditional declarations. Prevents declaring the variable
          # altogether if the depending variable's value does not match the one
          # provided.
          if-*)
            local depending_var="${key:3}"
            local depending_value=$(eval "echo \"\$$depending_var\"")

            if [[ "$depending_value" != "${values_arr[$key]}" ]]; then
              return 0
            fi
            ;;

          # Appends multiple values to the same var. Allow globals to be
          # declared multiple times to add values (space-separated string).
          append)
            if [[ -n "${ENV_VARS[$p_var_name|values]}" ]]; then
              ENV_VARS["${p_var_name}|values"]+=" ${values_arr[$key]}"
            else
              ENV_VARS["${p_var_name}|values"]="${values_arr[$key]}"
            fi
            ;;

          # Default.
          *)
            ENV_VARS["${p_var_name}|${key}"]="${values_arr[$key]}"
            ;;
        esac
      done
    fi
  fi

  # These globals allow dynamic handling of args and default values.
  if ! u_in_array $p_var_name ENV_VARS_UNIQUE_NAMES; then
    ((++ENV_VARS_COUNT))
    ENV_VARS_UNIQUE_NAMES+=($p_var_name)

    # This will be used to sort the array when complete.
    # See https://stackoverflow.com/a/39543809
    ENV_VARS['.sorting']+=" ${ENV_VARS_COUNT}|${p_var_name} "
  fi

  # Immediately attempt to export that variable unless explicitly prevented.
  # This allows conditional declarations in them (i.e. useful for settings that
  # need to adapt/react to each other).
  if [[ -z "$p_prevent_export" ]]; then
    u_assign_env_value "$p_var_name"
  fi
}

##
# [debug] Prints current environment globals and their associated data.
#
# @see global()
#
u_print_env() {
  local env_var_name
  local env_arr
  local key
  local val

  echo
  echo "Defined globals :"
  echo

  for env_var_name in ${ENV_VARS['.sorting']}; do
    u_str_split1 env_arr $env_var_name '|'
    env_var_name="${env_arr[1]}"

    eval "[[ -z \"\$$env_var_name\" ]] && echo \"$env_var_name\" \(empty\)";
    eval "[[ -n \"\$$env_var_name\" ]] && echo \"$env_var_name = \$$env_var_name\"";

    for key in ${ENV_VARS_UNIQUE_KEYS[@]}; do
      val="${ENV_VARS[$env_var_name|$key]}"
      if [[ -n "$val" ]]; then
        echo "  - ${key} = ${ENV_VARS[${env_var_name}|${key}]}";
      fi
    done
  done
  echo
}

##
# Gets env settings models lookup paths.
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
#   u_env_models_get_lookup_paths 'drupal-7--p-opigno,solr,memcached' 'docker-compose-3'
#   for env_model in "${ENV_MODELS_PATHS[@]}"; do
#     echo "$env_model"
#   done
#
u_env_models_get_lookup_paths() {
  local p_project_stack="$1"
  local p_provision_using="$2"

  export ENV_MODELS_PATHS

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

  ENV_MODELS_PATHS=()

  if [[ -n "$APP_VERSION" ]]; then
    local app_v
    local app_path=''
    local app_version_arr=()
    u_str_split1 app_version_arr "$APP_VERSION" '.'
  fi

  # Provisioning-related models.
  local p
  local p_arr=()
  u_env_item_split_version p_arr "$PROVISION_USING"
  if [[ -n "${p_arr[1]}" ]]; then
    local p_v
    local p_path="cwt/provision/${p_arr[0]}"
    local p_version_arr=()
    u_array_add_once "$p_path/vars.sh" ENV_MODELS_PATHS
    u_str_split1 p_version_arr "${p_arr[1]}" '.'
    for p_v in "${p_version_arr[@]}"; do
      p_path+="/$p_v"
      u_array_add_once "$p_path/vars.sh" ENV_MODELS_PATHS
    done
  else
    u_array_add_once "cwt/provision/${PROVISION_USING}/vars.sh" ENV_MODELS_PATHS
  fi

  local ss_arr=()
  for stack_service in "${STACK_SERVICES[@]}"; do
    u_env_item_split_version ss_arr "$stack_service"
    if [[ -n "${ss_arr[1]}" ]]; then
      u_env_models_lookup_version "cwt/provision/${ss_arr[0]}" "${ss_arr[1]}" true
    else
      u_array_add_once "cwt/provision/${stack_service}/vars.sh" ENV_MODELS_PATHS
      u_autoload_add_lookup_level "cwt/provision/${stack_service}/" 'vars.sh' "$PROVISION_USING" ENV_MODELS_PATHS
    fi
  done

  # Presets-related models.
  local sp_arr=()
  local sp_type
  local sp_types='provision app custom'

  for stack_preset in "${STACK_PRESETS[@]}"; do
    u_env_item_split_version sp_arr "$stack_preset"
    if [[ -n "${sp_arr[1]}" ]]; then
      for sp_type in $sp_types; do
        u_env_models_lookup_version "cwt/$sp_type/presets/${sp_arr[0]}" "${sp_arr[1]}" true
      done
    else
      for sp_type in $sp_types; do
        u_array_add_once "cwt/$sp_type/presets/${stack_preset}/vars.sh" ENV_MODELS_PATHS
        u_autoload_add_lookup_level "cwt/$sp_type/presets/${stack_preset}/" 'vars.sh' "$PROVISION_USING" ENV_MODELS_PATHS
      done
    fi
  done

  # App-related models.
  u_array_add_once "cwt/app/${APP}/env.vars.sh" ENV_MODELS_PATHS
  u_autoload_add_lookup_level "cwt/app/${APP}/env." 'vars.sh' "$PROVISION_USING" ENV_MODELS_PATHS

  if [[ -n "$APP_VERSION" ]]; then
    app_path="cwt/app/$APP"
    for app_v in "${app_version_arr[@]}"; do
      app_path+="/$app_v"
      u_array_add_once "$app_path/env.vars.sh" ENV_MODELS_PATHS
      u_autoload_add_lookup_level "$app_path/env." 'vars.sh' "$PROVISION_USING" ENV_MODELS_PATHS
    done
  fi
}

##
# Appends version number lookups.
#
# @see u_env_models_get_lookup_paths()
#
u_env_models_lookup_version() {
  local p_prefix="$1"
  local p_version="$2"
  local p_prepend_raw="$3"

  local v
  local path="$p_prefix"
  local version_arr=()

  if [[ "$p_prepend_raw" == true ]]; then
    u_array_add_once "$path/vars.sh" ENV_MODELS_PATHS
    u_autoload_add_lookup_level "$path/" 'vars.sh' "$PROVISION_USING" ENV_MODELS_PATHS
  fi

  u_str_split1 version_arr "$p_version" '.'
  for v in "${version_arr[@]}"; do
    path+="/$v"

    if [[ "$p_prepend_raw" == true ]]; then
      u_array_add_once "$path/vars.sh" ENV_MODELS_PATHS
    fi

    u_autoload_add_lookup_level "$path/" 'vars.sh' "$PROVISION_USING" ENV_MODELS_PATHS
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
#   u_env_item_split_version env_item_arr 'app_test_a-name-test-1.2'
#   for item_part in "${env_item_arr[@]}"; do
#     echo "$item_part"
#   done
#
u_env_item_split_version() {
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
