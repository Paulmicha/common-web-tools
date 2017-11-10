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
  local evn_arr
  local env_var_name

  for env_var_name in ${ENV_VARS['.sorting']}; do
    u_str_split1 evn_arr $env_var_name '|'
    env_var_name="${evn_arr[1]}"
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

  eval "local arg_val=\$P_${p_var}"
  local default_val="${ENV_VARS[$p_var|default]}"

  eval "export $p_var"

  if [[ -n "$arg_val" ]]; then
    eval "$p_var='$arg_val'"

  elif [[ $P_YES == 0 ]]; then
    if [[ -n "$default_val" ]]; then
      echo "Enter $p_var value,"
      eval "read -p \"or leave blank to use '$default_val' : \" $p_var"
    else
      eval "read -p \"Enter $p_var value : \" $p_var"
    fi
  fi

  local empty_test=$(eval "echo \"\$$p_var\"")
  if [[ (-z "$empty_test") && (-n "$default_val") ]]; then
    eval "$p_var='$default_val'"
  fi
}

##
# Adds new variable in $ENV_VARS.
#
# Increments a shared counter to maintain order, because some variables may depend
# on each other.
#
# @param 1 String : global variable name (readonly).
# @param 2 [optional] String :
#   values with syntax like : "[group]='the group name' [default]=test"
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
# @example
#   u_env_var_add 'MY_VAR_NAME' "[group]='the group name' [default]=test"
#
u_env_var_add() {
  local p_var_name="$1"
  local p_values="$2"

  # These globals allow dynamic handling of args and default values.
  if ! u_in_array $p_var_name ENV_VARS_UNIQUE_NAMES; then
    ((++ENV_VARS_COUNT))
    ENV_VARS_UNIQUE_NAMES+=($p_var_name)

    # This will be used to sort the array when complete.
    # See https://stackoverflow.com/a/39543809
    ENV_VARS['.sorting']+=" ${ENV_VARS_COUNT}|${p_var_name} "
  fi

  if [[ -n "$p_values" ]]; then
    local values_arr
    eval "declare -A values_arr=( $p_values )"
    for key in "${!values_arr[@]}"; do
      if ! u_in_array $key ENV_VARS_UNIQUE_KEYS; then
        ENV_VARS_UNIQUE_KEYS+=($key)
      fi
      ENV_VARS["${p_var_name}|${key}"]="${values_arr[$key]}"
    done
  fi
}

##
# Gets env settings models lookup paths.
#
# @param 1 [optional] String :
#   $PROJECT_STACK override (should exist in calling scope).
# @param 2 [optional] String :
#   $PROVISION_USING override (should exist in calling scope).
#
# @see u_stack_get_specs()
# @see u_env_item_split_version()
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
  u_env_models_lookup_ca_provisioning "cwt/provision/"

  u_stack_get_specs "$stack"

  local ss_arr=()
  for stack_service in "${STACK_SERVICES[@]}"; do
    u_env_item_split_version ss_arr "$stack_service"
    if [[ -n "${ss_arr[1]}" ]]; then
      u_env_models_lookup_ca_provisioning "cwt/provision/${ss_arr[0]}/"
      u_env_models_lookup_ca_provisioning "cwt/provision/${ss_arr[0]}/${ss_arr[1]}/"
    else
      u_env_models_lookup_ca_provisioning "cwt/provision/${stack_service}/"
    fi
  done

  local sp_arr=()
  for stack_preset in "${STACK_PRESETS[@]}"; do
    u_env_item_split_version sp_arr "$stack_preset"
    if [[ -n "${sp_arr[1]}" ]]; then
      u_env_models_lookup_ca_provisioning "cwt/provision/presets/$APP/${sp_arr[0]}/"
      u_env_models_lookup_ca_provisioning "cwt/provision/presets/$APP/${sp_arr[0]}/${sp_arr[1]}/"
      if [[ -n "$APP_VERSION" ]]; then
        u_env_models_lookup_ca_provisioning "cwt/provision/presets/$APP/$APP_VERSION/${sp_arr[0]}/"
        u_env_models_lookup_ca_provisioning "cwt/provision/presets/$APP/$APP_VERSION/${sp_arr[0]}/${sp_arr[1]}/"
      fi
    else
      u_env_models_lookup_ca_provisioning "cwt/provision/presets/$APP/${stack_preset}/"
      if [[ -n "$APP_VERSION" ]]; then
        u_env_models_lookup_ca_provisioning "cwt/provision/presets/$APP/$APP_VERSION/${stack_preset}/"
      fi
    fi
  done

  ENV_MODELS_PATHS+=("cwt/app/${APP}/env.vars.sh")
  if [[ -n "$APP_VERSION" ]]; then
    ENV_MODELS_PATHS+=("cwt/app/${APP}/$APP_VERSION/env.vars.sh")
    u_env_models_lookup_ca_provisioning "cwt/app/${APP}/$APP_VERSION/env."
  fi
}

##
# Conditionnally appends provisioning lookups.
#
# @see u_env_models_get_lookup_paths()
# @see u_env_item_split_version()
#
u_env_models_lookup_ca_provisioning() {
  local p_prefix="$1"

  local provisioning_arr=()
  u_env_item_split_version provisioning_arr "$provisioning"

  if [[ -n "${provisioning_arr[1]}" ]]; then
    ENV_MODELS_PATHS+=("${p_prefix}${provisioning_arr[0]}.vars.sh")
    ENV_MODELS_PATHS+=("${p_prefix}${provisioning}.vars.sh")
  else
    ENV_MODELS_PATHS+=("${p_prefix}${provisioning}.vars.sh")
  fi
}

##
# Gets PROJECT_STACK specifications.
#
# @param 1 String : the PROJECT_STACK to "dissect".
#
# @see u_str_split1()
# @see u_env_item_split_version()
# @see u_in_array()
#
# @example
#   u_stack_get_specs "$PROJECT_STACK"
#   echo "$APP"
#   echo "$APP_VERSION"
#   for stack_preset in "${STACK_PRESETS[@]}"; do
#     echo "$stack_preset"
#   done
#   for stack_service in "${STACK_SERVICES[@]}"; do
#     echo "$stack_service"
#   done
#
u_stack_get_specs() {
  local p_project_stack="$1"

  export APP
  export APP_VERSION
  export STACK_PRESETS
  export STACK_SERVICES

  # For bash version compatibility reasons, we replace variant separator '--'
  # with a single character unlikely to produce unexpected results given the
  # simple syntax of $PROJECT_STACK value.
  # See https://stackoverflow.com/a/45201229 (#7)
  local variant_sep='='
  local project_stack_r=${p_project_stack/--/"$variant_sep"}
  local stack_variant_arr
  u_str_split1 stack_variant_arr $project_stack_r $variant_sep

  APP="${stack_variant_arr[0]}"
  APP_VERSION=''
  STACK_PRESETS=()
  STACK_SERVICES=()

  local variants="${stack_variant_arr[1]}"

  local app_arr
  u_env_item_split_version app_arr $APP

  if [[ -n "${app_arr[1]}" ]]; then
    APP="${app_arr[0]}"
    APP_VERSION="${app_arr[1]}"
  fi

  # Applications may indicate their minimum required services using the
  # following files :
  # - cwt/app/$APP/required_services.sh :
  #     lists services required by any $APP version.
  # - cwt/app/$APP/$APP_VERSION/required_services.sh :
  #     lists, complements or overrides services required by that specific version.
  if [[ -f "cwt/app/$APP/required_services.sh" ]]; then
    . "cwt/app/$APP/required_services.sh"
    if [[ -f "cwt/app/$APP/$APP_VERSION/required_services.sh" ]]; then
      . "cwt/app/$APP/$APP_VERSION/required_services.sh"
    fi
    if [[ -n "$required_services" ]]; then
      if [[ -n "$variants" ]]; then
        variants="${variants},${required_services}"
      else
        variants="${required_services}"
      fi
    fi
  fi

  if [[ -n "$variants" ]]; then
    local variants_arr
    u_str_split1 variants_arr "$variants" ','

    local substr
    for variant_item in "${variants_arr[@]}"; do
      substr=${variant_item:0:2}

      if [[ "$substr" == 'p-' ]]; then
        STACK_PRESETS+=(${variant_item:2})
      elif [[ "$substr" != '..' ]]; then
        STACK_SERVICES+=($variant_item)
      fi
    done

    # Resolve alternatives. For each declared alternative, look if one of the
    # mutually exclusive options already exists in STACK_SERVICES. If not, add
    # the first one.
    # Example : cwt/app/drupal/required_services.sh
    local key
    local option
    local alt_options_arr
    for key in "${!alternatives[@]}"; do
      u_str_split1 alt_options_arr "${alternatives[$key]}" ','
      for option in "${alt_options_arr[@]}"; do
        if ! u_in_array $option STACK_SERVICES; then
          STACK_SERVICES+=($option)
          break
        fi
      done
    done
  fi
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
