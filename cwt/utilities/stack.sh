#!/bin/bash

##
# Stack-related utility functions.
#
# This file is dynamically loaded.
# @see cwt/bash_utils.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

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
  local stack_variant_arr=()
  u_str_split1 stack_variant_arr $project_stack_r $variant_sep

  APP="${stack_variant_arr[0]}"
  APP_VERSION=''
  STACK_PRESETS=()
  STACK_SERVICES=()

  local app_arr=()
  u_env_item_split_version app_arr "$APP"

  if [[ -n "${app_arr[1]}" ]]; then
    APP="${app_arr[0]}"
    APP_VERSION="${app_arr[1]}"
  fi

  # Resolve app dependencies declared in 'dependencies.sh' files for current app.
  local variants="${stack_variant_arr[1]}"
  u_stack_resolve_deps
}

##
# Loads dependency declarations and aggregates results in $STACK_SERVICES.
#
# Also populates STACK_PRESETS.
#
# Dependencies specify all services (or softwares) required to run the current
# project instance(s). They are used to list what will be provisioned on hosts.
#
# They are declared in files dynamically loaded in a similar way than env models.
# See cwt/env/README.md
#
# @requires the following variables in calling scope :
# - $variants
# - $APP
# - $APP_VERSION
# - $STACK_SERVICES
# - $STACK_PRESETS
# - $PROVISION_USING
#
# @see u_stack_get_specs()
# @see cwt/stack/init/aggregate_deps.sh
#
# @example
#   u_stack_resolve_deps
#   for stack_preset in "${STACK_PRESETS[@]}"; do
#     echo "$stack_preset"
#   done
#   for stack_service in "${STACK_SERVICES[@]}"; do
#     echo "$stack_service"
#   done
#
u_stack_resolve_deps() {
  local softwares
  local alternatives
  local software_version
  local dep_path
  declare -A alternatives
  declare -A software_version

  u_stack_deps_get_lookup_paths

  for dep_path in "${DEPS_LOOKUP_PATHS[@]}"; do
    softwares=''

    if [[ -f "$dep_path" ]]; then
      . "$dep_path"
    fi
    u_autoload_get_complement "$dep_path"

    if [[ -n "$softwares" ]]; then
      if [[ -n "$variants" ]]; then
        variants="${variants},${softwares}"
      else
        variants="${softwares}"
      fi
    fi
  done

  if [[ -n "$variants" ]]; then
    local variants_arr=()
    u_str_split1 variants_arr "$variants" ','

    local substr
    local vi_wo_ver
    local vi_arr
    for variant_item in "${variants_arr[@]}"; do
      substr="${variant_item:0:2}"

      if [[ "$substr" == 'p-' ]]; then
        STACK_PRESETS+=(${variant_item:2})

      elif [[ "$substr" != '..' ]]; then
        vi_wo_ver="$variant_item"

        u_env_item_split_version vi_arr "$variant_item"
        if [[ -n "${vi_arr[1]}" ]]; then
          vi_wo_ver="${vi_arr[0]}"
        fi

        if [[ -n "${software_version[$vi_wo_ver]}" ]]; then
          STACK_SERVICES+=("${vi_wo_ver}-${software_version[$vi_wo_ver]}")
        else
          STACK_SERVICES+=($variant_item)
        fi
      fi
    done

    u_stack_deps_resolve_alternatives
  fi
}

##
# Adds new software to the list of dependencies.
#
# @requires the following variables in calling scope :
# - $softwares
#
# @see u_stack_resolve_deps()
#
# For better readability in *dependencies.sh files, we exceptionally name that
# function without following the usual convention.
#
# @examples (write)
#   require my_software-name
#   require my_software-name-1.2.3
#
# @example (read)
#   u_autoload_print_lookup_paths DEPS_LOOKUP_PATHS "Stack dependencies"
#
require() {
  local p_input="$1"

  if [[ -n "$softwares" ]]; then
    softwares="${softwares},${p_input}"
  else
    softwares="${p_input}"
  fi
}

##
# Gets dependency files lookup paths.
#
# @requires the following globals in calling scope :
# - $APP
# - $APP_VERSION
# - $PROVISION_USING
# - $HOST_TYPE
# - $HOST_OS
#
# @exports result in global $DEPS_LOOKUP_PATHS.
#
# @see u_stack_resolve_deps()
# @see u_stack_get_specs()
# @see cwt/stack/init/aggregate_env_vars.sh
#
u_stack_deps_get_lookup_paths() {
  export DEPS_LOOKUP_PATHS
  DEPS_LOOKUP_PATHS=()

  # Provisioning-related dependencies.
  # u_autoload_add_lookup_level "cwt/provision/" 'dependencies.sh' "$PROVISION_USING" DEPS_LOOKUP_PATHS
  DEPS_LOOKUP_PATHS+=("cwt/provision/${HOST_TYPE}_host.dependencies.sh")
  u_autoload_add_lookup_level "cwt/provision/" 'dependencies.sh' "$HOST_OS" DEPS_LOOKUP_PATHS
  u_autoload_add_lookup_level "cwt/provision/" "${HOST_TYPE}_host.dependencies.sh" "$HOST_OS" DEPS_LOOKUP_PATHS
  u_autoload_add_lookup_level "cwt/provision/" 'dependencies.sh' "$PROVISION_USING" DEPS_LOOKUP_PATHS "$HOST_OS"
  u_autoload_add_lookup_level "cwt/provision/" "${HOST_TYPE}_host.dependencies.sh" "$PROVISION_USING" DEPS_LOOKUP_PATHS "$HOST_OS"

  # App-related dependencies.
  DEPS_LOOKUP_PATHS+=("cwt/app/$APP/dependencies.sh")
  # u_autoload_add_lookup_level "cwt/app/$APP/" 'dependencies.sh' "$PROVISION_USING" DEPS_LOOKUP_PATHS
  DEPS_LOOKUP_PATHS+=("cwt/app/$APP/${HOST_TYPE}_host.dependencies.sh")

  u_autoload_add_lookup_level "cwt/app/$APP/" 'dependencies.sh' "$HOST_OS" DEPS_LOOKUP_PATHS
  u_autoload_add_lookup_level "cwt/app/$APP/" "${HOST_TYPE}_host.dependencies.sh" "$HOST_OS" DEPS_LOOKUP_PATHS

  u_autoload_add_lookup_level "cwt/app/$APP/" 'dependencies.sh' "$PROVISION_USING" DEPS_LOOKUP_PATHS "$HOST_OS"
  u_autoload_add_lookup_level "cwt/app/$APP/" "${HOST_TYPE}_host.dependencies.sh" "$PROVISION_USING" DEPS_LOOKUP_PATHS "$HOST_OS"

  u_autoload_add_lookup_level "cwt/app/$APP/" 'dependencies.sh' "$INSTANCE_TYPE" DEPS_LOOKUP_PATHS "$HOST_OS"
  u_autoload_add_lookup_level "cwt/app/$APP/" "${HOST_TYPE}_host.dependencies.sh" "$INSTANCE_TYPE" DEPS_LOOKUP_PATHS "$HOST_OS"
  u_autoload_add_lookup_level "cwt/app/$APP/" 'dependencies.sh' "$INSTANCE_TYPE" DEPS_LOOKUP_PATHS "$PROVISION_USING"
  u_autoload_add_lookup_level "cwt/app/$APP/" "${HOST_TYPE}_host.dependencies.sh" "$INSTANCE_TYPE" DEPS_LOOKUP_PATHS "$PROVISION_USING"

  if [[ -n "$APP_VERSION" ]]; then
    local v
    local path="cwt/app/$APP"
    local version_arr=()

    u_str_split1 version_arr "$APP_VERSION" '.'
    for v in "${version_arr[@]}"; do
      path+="/$v"

      DEPS_LOOKUP_PATHS+=("$path/dependencies.sh")
      # u_autoload_add_lookup_level "$path/" 'dependencies.sh' "$PROVISION_USING" DEPS_LOOKUP_PATHS

      DEPS_LOOKUP_PATHS+=("$path/${HOST_TYPE}_host.dependencies.sh")

      u_autoload_add_lookup_level "$path/" 'dependencies.sh' "$HOST_OS" DEPS_LOOKUP_PATHS
      u_autoload_add_lookup_level "$path/" "${HOST_TYPE}_host.dependencies.sh" "$HOST_OS" DEPS_LOOKUP_PATHS

      u_autoload_add_lookup_level "$path/" 'dependencies.sh' "$PROVISION_USING" DEPS_LOOKUP_PATHS "$HOST_OS"
      u_autoload_add_lookup_level "$path/" "${HOST_TYPE}_host.dependencies.sh" "$PROVISION_USING" DEPS_LOOKUP_PATHS "$HOST_OS"

      u_autoload_add_lookup_level "$path/" 'dependencies.sh' "$INSTANCE_TYPE" DEPS_LOOKUP_PATHS "$HOST_OS"
      u_autoload_add_lookup_level "$path/" "${HOST_TYPE}_host.dependencies.sh" "$INSTANCE_TYPE" DEPS_LOOKUP_PATHS "$HOST_OS"
      u_autoload_add_lookup_level "$path/" 'dependencies.sh' "$INSTANCE_TYPE" DEPS_LOOKUP_PATHS "$PROVISION_USING"
      u_autoload_add_lookup_level "$path/" "${HOST_TYPE}_host.dependencies.sh" "$INSTANCE_TYPE" DEPS_LOOKUP_PATHS "$PROVISION_USING"
    done
  fi
}

##
# Resolves services alternatives.
#
# @requires the following variables in calling scope :
# - $alternatives
# - $software_version
# - $STACK_SERVICES
#
# Some applications require either one service (or software) OR another, like
# either mariadb or mysql or postgresql, or : either apache or nginx, etc.
# Such alternatives are declared using a naming convention as shown below.
#
# Only appends required service(s) if none of the alternatives is already provided.
# @see cwt/stack/init.sh
#
# @example
#   softwares='php,..db,..webserver'
#   alternatives['..db']='mariadb,mysql,postgresql'
#   alternatives['..webserver']='apache,nginx'
#
# @see u_stack_resolve_deps()
#
u_stack_deps_resolve_alternatives() {
  local key
  local option
  local alt_options_arr
  local found

  for key in "${!alternatives[@]}"; do
    match=0
    u_str_split1 alt_options_arr "${alternatives[$key]}" ','

    for option in "${alt_options_arr[@]}"; do
      if u_in_array $option STACK_SERVICES; then
        match=1
      fi
    done

    if [[ $match == 0 ]]; then
      for option in "${alt_options_arr[@]}"; do
        STACK_SERVICES+=($option)
        break
      done
    fi
  done
}
