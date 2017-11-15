#!/bin/bash

##
# Autoloading-related utility functions.
#
# This file is dynamically loaded.
# @see cwt/bash_utils.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Adds n+1 lookup paths in same dir, with or without version suffix.
#
# Allows specific overrides without adding extra depth in dir structure.
#
# @see u_stack_deps_get_lookup_paths()
# @see u_env_models_get_lookup_paths()
# @see cwt/stack/init/aggregate_env_vars.sh
#
# @example
#   u_autoload_add_lookup_level "cwt/app/$APP/" 'dependencies.sh' "$PROVISION_USING" DEPS_LOOKUP_PATHS
#   u_autoload_add_lookup_level "cwt/app/$APP/env." 'vars.sh' "$PROVISION_USING" ENV_MODELS_PATHS
#
u_autoload_add_lookup_level() {
  local p_prefix="$1"
  local p_suffix="$2"
  local p_name="$3"
  local p_lookups_var_name="$4"

  local name_version_arr=()
  u_env_item_split_version name_version_arr "$p_name"

  if [[ -n "${name_version_arr[1]}" ]]; then
    u_array_add_once "${p_prefix}${name_version_arr[0]}.${p_suffix}" $p_lookups_var_name

    local v
    local path="${p_prefix}${name_version_arr[0]}-"
    local version_arr=()

    u_str_split1 version_arr "${name_version_arr[1]}" '.'

    for v in "${version_arr[@]}"; do
      path+="$v."
      u_array_add_once "${path}${p_suffix}" $p_lookups_var_name
    done

  else
    u_array_add_once "${p_prefix}${p_name}.${p_suffix}" $p_lookups_var_name
  fi
}

##
# [debug] Prints aggregated lookup paths.
#
# @see cwt/stack/init/aggregate_env_vars.sh
#
# @example
#   u_autoload_print_lookup_paths DEPS_LOOKUP_PATHS "App dependencies"
#   u_autoload_print_lookup_paths ENV_MODELS_PATHS "Env models"
#
u_autoload_print_lookup_paths() {
  local p_arr=${1}[@]
  local p_title="$2"

  echo
  echo "$p_title lookup paths :"
  echo

  local path
  for path in ${!p_arr}; do
    echo "$path"
    if [[ -f "$path" ]]; then
      echo "  exists"
    fi
  done
  echo
}

##
# Returns bash code to eval for using potential override of given script.
#
# Checks if its counterpart exists in cwt/custom/overrides, and if it does,
# return the code that will source it and return early in main shell.
#
# Using eval allows this function to act in main shell scope, which we need
# in order to have "return" executed in current shell (to prevent running the
# rest of the calling script).
#
# This allows to completely replace a default CWT script.
#
# Usage :
# $ eval `u_autoload_override "$BASH_SOURCE"`
#
u_autoload_override() {
  local p_script_path="$1"
  local override=${p_script_path/cwt/"cwt/custom/overrides"}

  if [[ -f "$override" ]]; then
    echo ". $override ; return"
  fi
}

##
# Sources complement of given script.
#
# Checks if its counterpart exists in cwt/custom/complements, and if it does,
# source it in the scope of the calling script.
#
# This function is normally called after existing CWT generic script operations.
#
# Usage :
# $ u_autoload_get_complement "$BASH_SOURCE"
#
u_autoload_get_complement() {
  local p_script_path="$1"
  local complement=${p_script_path/cwt/"cwt/custom/complements"}

  if [[ -f "$complement" ]]; then
    . "$complement"
  fi
}
