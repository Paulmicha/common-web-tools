#!/bin/bash

##
# Config-related utility functions.
#
# This file is dynamically loaded.
# @see cwt/bash_utils.sh
#
# Convention : fonctions names are all prefixed by "u" (for "utility").
#

##
# Determines if chosen project stack uses any service.
#
# Usage :
# $ u_stack_uses 'db'
#
# u_stack_uses() {
#   local p_uses="$1"
#   # echo "PROJECT_STACK=$PROJECT_STACK"
#   # echo "p_uses=$p_uses"
#   if [[ -f "$complement" ]]; then
#     . "$complement"
#   fi
# }

u_stack_get_specs() {
  local stack_variant
  IFS='--' read -r -a stack_variant <<< "$PROJECT_STACK"
}
