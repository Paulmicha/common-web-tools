#!/usr/bin/env bash

##
# Utility functions to make sure scripts run once.
#
# TODO [wip] evaluate removal of this feature.
#
# Checks per host and/or app instance.
# TODO local and/or remote (2 ways).
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#
# @requires cwt/env/registry.sh
#

##
# Returns bash code to eval for preventing execution when script was already run.
#
# Using eval allows this function to act in main shell scope, which we need
# in order to have "return" executed in current shell (to prevent running the
# rest of the calling script when needed).
#
# @see u_check_once()
#
# Usage :
# $ eval `u_run_once_per_host "$BASH_SOURCE"`
#
u_run_once_per_host() {
  local p_script_path="$1"

  if $(u_check_once "$p_script_path" host); then
    echo "echo 'Running script $p_script_path for the first time for this host (will only run once)...'"
  else
    echo "echo 'The script $p_script_path must only run once per host, and was already run.' ; return"
  fi
}

##
# Returns bash code to eval for preventing execution when script was already run.
#
# Using eval allows this function to act in main shell scope, which we need
# in order to have "return" executed in current shell (to prevent running the
# rest of the calling script when needed).
#
# @see u_check_once()
#
# Usage :
# $ eval `u_run_once_per_instance "$BASH_SOURCE"`
#
u_run_once_per_instance() {
  local p_script_path="$1"

  if $(u_check_once "$p_script_path"); then
    echo "echo 'Running script $p_script_path for the first time on this instance (will only run once)...'"
  else
    echo "echo 'The script $p_script_path must only run once per instance, and was already run.' ; return"
  fi
}

##
# Arbitrary string check against custom file-based registry path.
#
# Simply checks if a file named after a transformation of the string passed as
# argument exists in CWT file-based registry's dir : /opt/cwt-registry
#
# Warning : the only transformation applied to the string passed as argument
# is u_slugify_u() in order to get a workable filename, so make sure the string
# is fit for that purpose. This may also lead to false positives.
#
# @see u_slugify_u()
# @see u_file_registry_get_path()
#
# @param 1 String : Unsually the script path or function call, with or without
#   arguments. This could be anything, the point being uniquely identifying an
#   action so it is only run once per host (until the corresponding file "flag"
#   is deleted).
# @param 2 String [optional] : the namespace to use for this registry entry.
#   Can be 'host' or any string. Default: $INSTANCE_DOMAIN.
#
# @example : check script has run once per instance
#   if $(u_check_once "$BASH_SOURCE"); then
#     echo "Proceed."
#   else
#     echo "Abort : this script has already been run on this host."
#     return
#   fi
#
# @example : check script has run once per host
#   if $(u_check_once "$BASH_SOURCE" 'host'); then
#     echo "Proceed."
#   else
#     echo "Abort : this script has already been run on this host."
#     return
#   fi
#
u_check_once() {
  local p_namespace="$2"
  local reg_file=$(u_file_registry_get_path "$1" $p_namespace)

  if [[ ! -f $reg_file ]]; then
    touch $reg_file
    return
  fi

  false
}
