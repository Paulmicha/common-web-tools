#!/bin/bash

##
# Provisioning-related utility functions.
#
# This file is dynamically loaded.
# @see cwt/bash_utils.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Pre-processes host provision during stack setup.
#
# @requires the following globals in calling scope :
# - $PROVISION_USING
# - $HOST_OS
#
# @see u_host_provision()
#
u_provisioning_preprocess() {
  local provision_type
  local provision_version_arr

  provision_type="$PROVISION_USING"
  u_env_item_split_version provision_version_arr "$PROVISION_USING"
  if [[ -n "${provision_version_arr[1]}" ]]; then
    provision_type="${provision_version_arr[0]}"
  fi

  if [[ "$provision_type" == 'docker-compose' ]]; then
    # todo
  elif [[ "$provision_type" == 'ansible' ]]; then
    # todo
  fi
}
