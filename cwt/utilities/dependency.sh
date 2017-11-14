#!/bin/bash

##
# App dependency related utility functions.
#
# Dependencies specify all services (or softwares) required to run the current
# project instance(s). They are used to list what will be provisioned on hosts.
#
# They are declared in files dynamically loaded in a similar way than env models.
# See cwt/env/README.md
#
# This file is dynamically loaded.
# @see cwt/bash_utils.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Loads dependency declarations and aggregates results in $STACK_SERVICES.
#
# Also populates STACK_PRESETS.
# See cwt/env/README.md
#
# @requires the following globals in calling scope :
# - $APP
# - $APP_VERSION
# - $STACK_SERVICES
# - $STACK_PRESETS
#
# @see u_stack_get_specs()
#
# @example
#   u_app_get_deps drupal 8.4
#   echo "$APP"
#   echo "$APP_VERSION"
#   for stack_preset in "${STACK_PRESETS[@]}"; do
#     echo "$stack_preset"
#   done
#   for stack_service in "${STACK_SERVICES[@]}"; do
#     echo "$stack_service"
#   done
#
u_app_resolve_deps() {
  local softwares
  local alternatives
  local software_version

  declare -A alternatives
  declare -A software_version

  u_app_deps_get_lookup_paths

  local dep_path
  for dep_path in "${DEPS_LOOKUP_PATHS[@]}"; do
    if [[ -f "cwt/app/$APP/dependencies.sh" ]]; then
      . "$dep_path"

      if [[ -n "$softwares" ]]; then
        if [[ -n "$variants" ]]; then
          variants="${variants},${softwares}"
        else
          variants="${softwares}"
        fi
      fi
    fi
  done

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

    u_app_deps_resolve_alternatives
  fi
}

##
# Gets dependency files lookup paths.
#
# @requires the following globals in calling scope :
# - $APP
# - $APP_VERSION
#
# @exports result in global $DEPS_LOOKUP_PATHS.
#
u_app_deps_get_lookup_paths() {
  export DEPS_LOOKUP_PATHS
  DEPS_LOOKUP_PATHS=()

  DEPS_LOOKUP_PATHS+=("cwt/app/$APP/dependencies.sh")

  if [[ -n "$APP_VERSION" ]]; then
    local v
    local path="cwt/app/$APP"
    local version_arr=()

    u_str_split1 version_arr "$APP_VERSION" '.'
    for v in "${version_arr[@]}"; do
      path+="/$v"

      DEPS_LOOKUP_PATHS+=("$path/dependencies.sh")
    done
  fi
}

##
# Resolves services alternatives.
#
# @requires the following variables in calling scope :
# - $alternatives
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
# @see u_app_resolve_deps()
#
u_app_deps_resolve_alternatives() {
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
