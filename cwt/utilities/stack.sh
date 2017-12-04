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
# @exports String APP
# @exports String APP_VERSION
# @exports Array STACK_PRESETS (via u_stack_get_presets)
# @exports Array STACK_SERVICES
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
  export STACK_SERVICES

  STACK_SERVICES=()

  APP=$(u_stack_get_part app "$p_project_stack")
  APP_VERSION=$(u_stack_get_part app_version "$p_project_stack")

  # Resolve app dependencies declared in 'dependencies.sh' files for current app.
  u_stack_get_presets "$p_project_stack"
  u_stack_resolve_deps "$p_project_stack"
}

##
# Gets presets in PROJECT_STACK "variants" part.
#
# @param 1 String : the PROJECT_STACK value.
#
# @exports Array STACK_PRESETS
#
# @example
#   u_stack_get_presets "drupal-8--p-contenta-1,redis,solr"
#   for stack_preset in "${STACK_PRESETS[@]}"; do
#     echo "$stack_preset"
#   done
#
u_stack_get_presets() {
  local p_project_stack="$1"
  local variants=$(u_stack_get_part variants "$p_project_stack")
  local variants_arr=()

  export STACK_PRESETS
  STACK_PRESETS=()

  u_str_split1 variants_arr "$variants" ','

  local substr
  local variant_item

  for variant_item in "${variants_arr[@]}"; do
    substr="${variant_item:0:2}"

    if [[ "$substr" == 'p-' ]]; then
      STACK_PRESETS+=(${variant_item:2})
    fi
  done
}

##
# Extracts a part of the PROJECT_STACK value.
#
# @param 1 String : the part we want.
# @param 2 String : the $PROJECT_STACK value.
#
# @example : get the "app" and "app_version" parts :
#   app=$(u_stack_get_part app "drupal-8--p-contenta-1,redis,solr")
#   echo "$app" # outputs "drupal"
#   app_version=$(u_stack_get_part app_version "drupal-8--p-contenta-1,redis,solr")
#   echo "$app_version" # outputs "8"
#
# @example : get the "variants" part :
#   variants=$(u_stack_get_part variants "drupal-8--p-contenta-1,redis,solr")
#   echo "$variants" # outputs "p-contenta-1,redis,solr"
#
u_stack_get_part() {
  local p_part="$1"
  local p_project_stack="$2"

  # For bash version compatibility reasons, we replace variant separator '--'
  # with a single character unlikely to produce unexpected results given the
  # simple syntax of $PROJECT_STACK value.
  # See https://stackoverflow.com/a/45201229 (#7)
  local variant_sep='='
  local project_stack_r=${p_project_stack/--/"$variant_sep"}
  local stack_variant_arr=()
  u_str_split1 stack_variant_arr "$project_stack_r" "$variant_sep"

  case "$p_part" in

    # For these parts, the argument is the local variable name.
    app|app_version)
      local app="${stack_variant_arr[0]}"
      local app_version=''
      local app_arr=()

      u_env_item_split_version app_arr "$app"

      if [[ -n "${app_arr[1]}" ]]; then
        app="${app_arr[0]}"
        app_version="${app_arr[1]}"
      fi

      eval "echo \"\$$p_part\""
      ;;

    variants)
      echo "${stack_variant_arr[1]}"
      ;;
  esac
}

##
# Loads dependency declarations and aggregates results in $STACK_SERVICES.
#
# Dependencies specify all services (or softwares) required to run the current
# project instance(s). They are used to list what will be provisioned on hosts.
#
# See cwt/env/README.md
#
# @param 1 String : the $PROJECT_STACK value.
#
# @requires the following variables in calling scope :
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
#   u_stack_resolve_deps "$PROJECT_STACK"
#   for stack_preset in "${STACK_PRESETS[@]}"; do
#     echo "$stack_preset"
#   done
#   for stack_service in "${STACK_SERVICES[@]}"; do
#     echo "$stack_service"
#   done
#
u_stack_resolve_deps() {
  local p_project_stack="$1"

  local variants
  local softwares
  local alternatives
  local software_version
  local dep_path

  declare -A alternatives
  declare -A software_version

  variants=$(u_stack_get_part variants "$p_project_stack")

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
        u_array_add_once "${variant_item:2}" STACK_PRESETS

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
# - $STACK_PRESETS
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
  u_stack_deps_add_lookup_variants_by_path "cwt/provision"

  # App-related dependencies.
  u_stack_deps_add_lookup_variants_by_path "cwt/app/$APP"
  if [[ -n "$APP_VERSION" ]]; then
    local v
    local path="cwt/app/$APP"
    local version_arr=()

    u_str_split1 version_arr "$APP_VERSION" '.'
    for v in "${version_arr[@]}"; do
      path+="/$v"
      u_stack_deps_add_lookup_variants_by_path "$path"
    done
  fi

  # Presets-related dependencies.
  local sp_arr=()
  local sp_v
  local sp_path
  local sp_type
  local sp_types='provision app custom'

  for stack_preset in "${STACK_PRESETS[@]}"; do
    u_env_item_split_version sp_arr "$stack_preset"
    if [[ -n "${sp_arr[1]}" ]]; then
      for sp_type in $sp_types; do
        sp_path="cwt/$sp_type/presets"
        for sp_v in "${sp_arr[@]}"; do
          sp_path+="/$sp_v"
          u_stack_deps_add_lookup_variants_by_path "$sp_path"
        done
      done
    else
      for sp_type in $sp_types; do
        u_stack_deps_add_lookup_variants_by_path "cwt/$sp_type/presets/${stack_preset}"
      done
    fi
  done
}

##
# Internal deps lookups helper.
#
u_stack_deps_add_lookup_variants_by_path() {
  local p_path="$1"

  if [[ "$p_path" != 'cwt/provision' ]]; then
    DEPS_LOOKUP_PATHS+=("$p_path/dependencies.sh")
  fi

  DEPS_LOOKUP_PATHS+=("$p_path/${HOST_TYPE}_host.dependencies.sh")
  u_autoload_add_lookup_level "$p_path/" 'dependencies.sh' "$HOST_OS" DEPS_LOOKUP_PATHS
  u_autoload_add_lookup_level "$p_path/" "${HOST_TYPE}_host.dependencies.sh" "$HOST_OS" DEPS_LOOKUP_PATHS
  u_autoload_add_lookup_level "$p_path/" 'dependencies.sh' "$PROVISION_USING" DEPS_LOOKUP_PATHS "$HOST_OS"
  u_autoload_add_lookup_level "$p_path/" "${HOST_TYPE}_host.dependencies.sh" "$PROVISION_USING" DEPS_LOOKUP_PATHS "$HOST_OS"
  u_autoload_add_lookup_level "$p_path/" 'dependencies.sh' "$INSTANCE_TYPE" DEPS_LOOKUP_PATHS "$HOST_OS"
  u_autoload_add_lookup_level "$p_path/" "${HOST_TYPE}_host.dependencies.sh" "$INSTANCE_TYPE" DEPS_LOOKUP_PATHS "$HOST_OS"
  u_autoload_add_lookup_level "$p_path/" 'dependencies.sh' "$INSTANCE_TYPE" DEPS_LOOKUP_PATHS "$PROVISION_USING"
  u_autoload_add_lookup_level "$p_path/" "${HOST_TYPE}_host.dependencies.sh" "$INSTANCE_TYPE" DEPS_LOOKUP_PATHS "$PROVISION_USING"
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

##
# TODO Adds or installs a service required by the current project instance.
#
# WIP - refacto in progress : this requires more thinking before implementing :
# tools like Lando or static sites projects won't need the same kind of process.
#
# For docker-compose provisioning, this will append services to the YAML file.
# For ansible provisioning, this will append them to the playbook.
# For scripts, this checks if software is already installed. If not, it will
# attempt to find and execute a setup script matching the local host OS for each
# service.
#
# @requires the following globals in calling scope :
# - $PROVISION_USING
# - $HOST_OS
#
# @see u_host_provision()
#
# u_stack_add_service() {
# }
