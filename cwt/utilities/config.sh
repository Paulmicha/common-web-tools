#!/bin/bash

##
# Config-related utility functions.
#
# See cwt/env/README.md
#
# This file is dynamically loaded.
# @see cwt/bash_utils.sh
#
# Convention : fonctions names are all prefixed by "u" (for "utility").
#

##
# Gets PROJECT_STACK specifications.
#
# @param 1 String : the PROJECT_STACK to "dissect".
#
# @requires u_str_split1()
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
  export STACK_PRESETS
  export STACK_SERVICES

  # For bash version compatibility reasons, we replace variant separator '--'
  # with a single character unlikely to produce unexpected results given the
  # simple syntax of $PROJECT_STACK value.
  # See https://stackoverflow.com/a/45201229 (#7)
  local variant_sep='='
  local project_stack_r=${p_project_stack/--/"$variant_sep"}
  local stack_variant_arr
  u_str_split1 stack_variant_arr $project_stack_r $variant_sep

  APP="${stack_variant_arr[0]}"
  APP_VERSION=''
  STACK_PRESETS=()
  STACK_SERVICES=()

  local app_arr
  u_str_split1 app_arr $APP '-'

  if [[ -n "${app_arr[1]}" ]]; then
    APP="${app_arr[0]}"
    APP_VERSION="${app_arr[1]}"
  fi

  if [[ -n "${stack_variant_arr[1]}" ]]; then
    local variants_arr
    u_str_split1 variants_arr "${stack_variant_arr[1]}" ','

    local substr
    for variant_item in "${variants_arr[@]}"; do
      substr=${variant_item:0:2}

      if [[ "$substr" == 'p-' ]]; then
        STACK_PRESETS+=(${variant_item:2})
      else
        STACK_SERVICES+=($variant_item)
      fi
    done
  fi
}
