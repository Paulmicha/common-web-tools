#!/bin/bash

##
# Local project registry.
#
# Loads the file containing registry Bash utility functions corresponding to
# this env's reg backend. Allows override from 'cwt/custom' dir.
#
# Note : each registry implementation must provide at least these 3 functions :
# - u_registry_set_val()
# - u_registry_get_val()
# - u_check_once()
#
# @example : store some value into the local project registry.
#   u_registry_set_val 'key' 'value'
#
# @example : read some value into the local project registry.
#   VAL=$(u_registry_get_val 'key')
#   if [[ -z "$VAL" ]]; then
#     echo "Nothing in store."
#   else
#     echo "Value = $VAL"
#   fi
#
# @example : implement "once per host (per user)" flag from inside a sourced
#   script using the local project registry.
#   THIS_ABS_PATH=$(u_get_script_path ${BASH_SOURCE[0]})
#   if $(u_check_once "${THIS_ABS_PATH} arg"); then
#     echo "Proceed."
#   else
#     echo "Abort : this has already been run once."
#     return
#   fi
#
# @see cwt/env/registry_file.sh
#
# Usage from project root dir :
# . cwt/env/registry.sh
#

# Allow custom override for this script.
eval `u_autoload_override "$BASH_SOURCE"`

# Load implementation corresponding to the backend type env setting.
if [[ -f "cwt/env/registry/${REG_BACKEND}.sh" ]]; then
  . "cwt/env/registry/${REG_BACKEND}.sh"
fi
