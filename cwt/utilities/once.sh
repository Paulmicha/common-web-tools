#!/bin/bash

##
# Utility functions to make sure scripts run once.
#
# Checks per host and/or app instance.
# TODO local and/or remote (2 ways).
#
# This file is dynamically loaded.
# @see cwt/bash_utils.sh
#
# Convention : fonctions names are all prefixed by "u" (for "utility").
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
  local abs_path=$(u_get_script_path ${p_script_path[0]})

  if $(u_check_once "$abs_path"); then
    echo "echo 'Running script $p_script_path for the first time on this host (will only run once)...'"
  else
    echo "echo 'The script $p_script_path must only run once per host, and was already run.' ; return"
  fi
}
