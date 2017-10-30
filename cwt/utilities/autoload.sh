#!/bin/bash

##
# Autoloading-related utility functions.
#
# This file is dynamically loaded.
# @see cwt/bash_utils.sh
#
# Convention : fonctions names are all prefixed by "u" (for "utility").
#

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
  local override=${p_script_path/cwt/"cwt/custom/complements"}

  if [[ -f "$override" ]]; then
    . "$override"
  fi
}
