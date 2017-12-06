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
# [wip] TODO Autoloads all matching includes.
#
u_autoload_all_includes() {
  echo "debug u_autoload_all_includes() : $@"

  # [wip] TODO valuate using u_hook() to either produce filepath lookups OR dynamic function names ?
  # examples :
  # u_hook 'file-lookup' "$@"
  # u_hook 'function' "$@"
}

##
# [wip] TODO Autoloads the most "specific" include only.
#
u_autoload_most_specific_include() {
  echo "debug u_autoload_most_specific_include() : $@"
}

##
# Adds n+1 lookup paths in same dir, with or without version suffix.
#
# Allows specific overrides without adding extra depth in dir structure.
#
# @see u_stack_deps_get_lookup_paths()
# @see u_global_get_includes_lookup_paths()
# @see cwt/stack/init/aggregate_env_vars.sh
#
# @example
#   u_autoload_add_lookup_level "cwt/app/$APP/" 'dependencies.sh' "$PROVISION_USING" DEPS_LOOKUP_PATHS
#   u_autoload_add_lookup_level "cwt/app/$APP/env." 'vars.sh' "$PROVISION_USING" GLOBALS_INCLUDES_PATHS
#
u_autoload_add_lookup_level() {
  local p_prefix="$1"
  local p_suffix="$2"
  local p_name="$3"
  local p_lookups_var_name="$4"
  local p_extra_level_name="$5"
  local p_sep="$6"

  local sep="."
  if [[ -n "$p_sep" ]]; then
    sep="$p_sep"
  fi

  local name_version_arr=()
  u_instance_item_split_version name_version_arr "$p_name"

  if [[ -n "${name_version_arr[1]}" ]]; then
    u_array_add_once "${p_prefix}${name_version_arr[0]}.${p_suffix}" $p_lookups_var_name

    if [[ -n "$p_extra_level_name" ]]; then
      u_autoload_add_lookup_level "${p_prefix}${name_version_arr[0]}." $p_suffix $p_extra_level_name $p_lookups_var_name
    fi

    local v
    local path="${p_prefix}${name_version_arr[0]}-"
    local version_arr=()

    u_str_split1 version_arr "${name_version_arr[1]}" '.'

    for v in "${version_arr[@]}"; do
      path+="${v}${sep}"
      u_array_add_once "${path}${p_suffix}" $p_lookups_var_name

      if [[ -n "$p_extra_level_name" ]]; then
        u_autoload_add_lookup_level "${path}" $p_suffix $p_extra_level_name $p_lookups_var_name
      fi
    done

  else
    u_array_add_once "${p_prefix}${p_name}${sep}${p_suffix}" $p_lookups_var_name

    if [[ -n "$p_extra_level_name" ]]; then
      u_autoload_add_lookup_level "${p_prefix}${p_name}${sep}" $p_suffix $p_extra_level_name $p_lookups_var_name
    fi
  fi
}

##
# [debug] Prints aggregated lookup paths.
#
# @see cwt/stack/init/aggregate_env_vars.sh
#
# @example
#   u_autoload_print_lookup_paths DEPS_LOOKUP_PATHS "App dependencies"
#   u_autoload_print_lookup_paths GLOBALS_INCLUDES_PATHS "Env includes"
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
# @example
#   eval `u_autoload_override "$BASH_SOURCE"`
#
# Another use is to break a lookup loop if a replacement exists.
# @example
#   for prov_model in "${PROV_INCLUDES_LOOKUP_PATHS[@]}"; do
#     if [[ -f "$prov_model" ]]; then
#       eval $(u_autoload_override "$prov_model" 'continue')
#       # (snip) default exec goes here.
#     fi
#   done
#
u_autoload_override() {
  local p_script_path="$1"
  local p_operand="$2"

  local operand='return'
  if [[ -n "$p_operand" ]]; then
    operand="$p_operand"
  fi

  local override=${p_script_path/cwt/"$(u_autoload_get_custom_dir)/overrides"}
  if [[ -f "$override" ]]; then
    echo ". $override ; $operand"
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
  local complement=${p_script_path/cwt/"$(u_autoload_get_custom_dir)/complements"}

  if [[ -f "$complement" ]]; then
    . "$complement"
  fi
}

##
# Returns customizations base dir.
#
# If global CWT_CUSTOM_DIR exists in calling scope, it will be used. Otherwise,
# it will return the hardcoded default value 'cwt/custom'.
#
# @see cwt/custom/README.md
#
u_autoload_get_custom_dir() {
  local base_dir='cwt/custom'
  if [[ -n "$CWT_CUSTOM_DIR" ]]; then
    base_dir="$CWT_CUSTOM_DIR"
  fi
  echo "$base_dir"
}
