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
# Gets env settings models lookup paths.
#
# @param 1 [optional] String : $PROJECT_STACK override (should exist in calling scope).
# @param 2 [optional] String : $PROVISION_USING override (should exist in calling scope).
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
        variants="${variants}${required_services}"
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
      else
        STACK_SERVICES+=($variant_item)
      fi
    done

    # TODO implement mutually exclusive alternatives. Ex :
    # @see cwt/app/drupal/required_services.sh
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
