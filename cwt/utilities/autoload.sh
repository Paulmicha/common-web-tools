#!/usr/bin/env bash

##
# Autoloading-related utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Adds n+1 lookup paths in same dir, with or without version suffix.
#
# Allows specific overrides without adding extra depth in dir structure.
#
# @see u_stack_deps_get_lookup_paths()
# @see u_global_get_includes_lookup_paths()
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

    u_str_split1 'version_arr' "${name_version_arr[1]}" '.'

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
# Allows to optionally replace or bypass a default script include (sourcing).
#
# Checks if its counterpart exists in scripts/overrides, and if it does,
# return the code that will source it and return early in main shell.
#
# This function works by populating a variable named inc_override_evaled_code
# with code to be evaluated (see examples below).
#
# Using 'eval' allows this function to act in main shell scope, which we need
# in order to have "return" executed in current shell (to prevent running the
# rest of the calling script).
#
# @param 1 String the original file include path relative to PROJECT_DOCROOT.
# @param 2 [optional] String the statement to use when an override is found.
# @param 3 [optional] String custom statement allowing to react differently.
#
# @see u_cwt_extensions()
# @see cwt/bootstrap.sh
#
# @example
#   # Default behavior : source override match (if exists) and return early.
#   u_autoload_override "$BASH_SOURCE"
#   eval "$inc_override_evaled_code"
#
#   # Break a lookup loop if an override is found.
#   for prov_model in "${PROV_INCLUDES_LOOKUP_PATHS[@]}"; do
#     if [[ -f "$prov_model" ]]; then
#       u_autoload_override "$prov_model" 'continue'
#       eval "$inc_override_evaled_code"
#       # (snip) rest goes here - only executed if no matching override is found.
#     fi
#   done
#
#   # Only get the override filepath to customize reaction.
#   local override_file=''
#   local extensions_declaration="cwt/cwt_extensions.txt"
#   u_autoload_override "$extensions_declaration" '' 'override_file="$override"'
#   eval "$inc_override_evaled_code"
#   if [[ -n "$override_file" ]]; then
#     echo "An override has been found : $override_file"
#   fi
#
u_autoload_override() {
  local p_script_path="$1"
  local p_operand="$2"
  local p_reaction="$3"

  local operand='return'
  if [[ -n "$p_operand" ]]; then
    operand="$p_operand"
  fi

  local base_dir='scripts'
  if [[ -n "$PROJECT_SCRIPTS" ]]; then
    base_dir="$PROJECT_SCRIPTS"
  fi

  inc_override_evaled_code=''
  local override=${p_script_path/cwt/"$base_dir/overrides"}

  if [[ -f "$override" ]]; then
    # Allows to react to the presence of an override differently.
    if [[ -n "$p_reaction" ]]; then
      inc_override_evaled_code="$p_reaction"
    # Normal behavior (see examples in function docblock).
    else
      inc_override_evaled_code=". $override ; $operand"
    fi
  fi
}

##
# [TODO document new arg] Sources complement of given script.
#
# Checks if its counterpart exists in scripts/complements, and if it does,
# source it in the scope of the calling script.
#
# This function is normally called after existing CWT generic script operations.
#
# @example
#   u_autoload_get_complement "$BASH_SOURCE"
#
u_autoload_get_complement() {
  local p_script_path="$1"
  local p_reaction="$2"

  local base_dir='scripts'
  if [[ -n "$PROJECT_SCRIPTS" ]]; then
    base_dir="$PROJECT_SCRIPTS"
  fi

  local complement=${p_script_path/cwt/"$base_dir/complements"}

  if [[ -f "$complement" ]]; then

    # Allows to react to the presence of a complement differently.
    if [[ "$p_reaction" == 'get_complement_filepath' ]]; then
      echo "$complement"
    else
      . "$complement"
    fi
  fi
}
