#!/usr/bin/env bash

##
# Instance-related utility functions.
#
# See cwt/env/README.md
#
# This file is dynamically loaded.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Gets current local instance state.
#
# Determines if instance was already initialized, if its services are running...
# TODO [wip] workaround instance state limitations (e.g. unhandled shutdown).
#
# @export INSTANCE_STATE global var.
#
# @example
#   u_instance_get_state
#   echo "$INSTANCE_STATE" # E.g. prints 'initialized'.
#
u_instance_get_state() {
  local env_instance_state="$INSTANCE_STATE"
  local local_instance_state="$(u_registry_get_val 'instance_state')"

  if [[ -n "$local_instance_state" ]]; then
    export INSTANCE_STATE="$local_instance_state"
  elif [[ -z "$INSTANCE_STATE" ]]; then
    export INSTANCE_STATE='new'
  fi

  # Allow custom implementations to react to state getter calls (e.g. to notify
  # in case of incoherences or errors, and/or to alter its value) ?
  # TODO [wip] postponed + refacto CWT hooks.
  # u_hook_app 'get' 'instance_state' '' 'stack'
}

##
# Sets current local instance state.
#
# TODO [wip] workaround instance state limitations (e.g. unhandled shutdown).
#
# @export INSTANCE_STATE global var.
#
# @example
#   u_instance_set_state 'running'
#   echo "$INSTANCE_STATE" # E.g. prints 'running'.
#
u_instance_set_state() {
  local p_new_state="$1"

  if [[ -n "$p_new_state" ]]; then
    u_registry_set_val 'instance_state' "$p_new_state"
    export INSTANCE_STATE="$p_new_state"
  fi

  # Allow custom implementations to react to state getter calls (e.g. to notify
  # in case of incoherences or errors) ?
  # TODO [wip] postponed + refacto CWT hooks.
  # u_hook_app 'set' 'instance_state' '' 'stack'
}

##
# Separates an env item name from its version number.
#
# Follows a simplistic syntax : inputting 'app_test_a-name-test-1.2'
# -> output ['app_test_a-name-test', '1.2']
#
# @param 1 The variable name that will contain the array (in calling scope).
# @param 2 String to separate.
#
# @example
#   u_instance_item_split_version env_item_arr 'app_test_a-name-test-1.2'
#   for item_part in "${env_item_arr[@]}"; do
#     echo "$item_part"
#   done
#
u_instance_item_split_version() {
  local p_var_name="$1"
  local p_str="$2"

  eval "${p_var_name}=()"

  local version_part="${p_str##*-}"

  # If last part doesn't match only numbers and dots, just return [$p_str].
  if [[ ! "$version_part" =~ [0-9.]+$ ]]; then
    eval "${p_var_name}+=(\"$p_str\")"
    return
  fi

  local name_part="${p_str%-*}"

  if [[ -n "$name_part" ]]; then
    eval "${p_var_name}+=(\"$name_part\")"
  fi

  if [[ (-n "$version_part") && ("$version_part" != "$name_part") ]]; then
    eval "${p_var_name}+=(\"$version_part\")"
  fi
}

##
# Gets default value for this project instance's domain.
#
# Some projects may have DNS-dependant features to test locally, so we
# provide a default one based on project docroot dirname. In these cases, the
# necessary domains must be added to the device's hosts file (usually located
# in /etc/hosts or C:\Windows\System32\drivers\etc\hosts). Alternatives also
# exist to achieve this.
#
# The generated domain uses 'io' TLD in order to avoid trigger searches from
# some browsers address bars (like Chrome's).
#
u_get_instance_domain() {
  local lh="$(u_get_localhost_ip)"

  if [[ -z "$lh" ]]; then
    lh='local'
  fi

  if [[ $lh == "192.168."* ]]; then
    lh="${lh//192.168./lan-}"
  else
    lh="host-${lh}"
  fi

  echo "${PWD##*/}.${lh//./-}.io"
}
