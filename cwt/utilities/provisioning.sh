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
# TODO Executes installation script corresponding to provisioning method.
#
# @see cwt/provision/dependencies.sh
#
# u_provisioning_install_deps() {
# }

##
# Pre-processes host provision during stack setup.
#
# Ansible and Docker-compose use *.yml files to "wrap" a stack as a complete
# installation by listing their components (and more).
# We'll use env models like *vars.sh files, but using *dist.yml suffix instead.
#
# TODO for hosts where ansible is installed and docker-compose is chosen to
# provision current project instance, we may choose to install dependencies
# using existing roles like :
# - https://github.com/nickjj/ansible-docker
# - https://github.com/geerlingguy/ansible-role-docker
# - https://github.com/weareinteractive/ansible-docker-compose
# - https://github.com/weareinteractive/ansible-docker
#
# TODO this also raises another question : should we support provisioning using
# both Ansible *and* docker-compose (provision the provisioning) ?
# See also https://docs.devwithlando.io/started.html
#
# @requires the following globals in calling scope :
# - $PROVISION_USING
# - $HOST_TYPE
# - $HOST_OS
# - $INSTANCE_TYPE
#
# @see u_host_provision()
# @see u_provisioning_models_get_lookup_paths()
#
u_provisioning_preprocess() {
  local provision_type
  local provision_version_arr

  u_provisioning_models_get_lookup_paths

  provision_type="$PROVISION_USING"
  u_env_item_split_version provision_version_arr "$PROVISION_USING"
  if [[ -n "${provision_version_arr[1]}" ]]; then
    provision_type="${provision_version_arr[0]}"
  fi

  # TODO use sed to replace placeholders inside a copy instead of sourcing.
  # local prov_model
  # for prov_model in "${PROV_MODELS_LOOKUP_PATHS[@]}"; do
  #   if [[ -f "$prov_model" ]]; then
  #     eval $(u_autoload_override "$prov_model" 'continue')
  #     . "$prov_model"
  #   fi
  # done
}

##
# Gets provisioning models files lookup paths.
#
# @requires the following globals in calling scope :
# - $PROVISION_USING
# - $HOST_TYPE
# - $HOST_OS
# - $INSTANCE_TYPE
#
# @exports result in global $PROV_MODELS_LOOKUP_PATHS.
#
# @see u_provisioning_preprocess()
# @see cwt/stack/setup.sh
#
u_provisioning_models_get_lookup_paths() {
  export PROV_MODELS_LOOKUP_PATHS
  PROV_MODELS_LOOKUP_PATHS=()

  u_autoload_add_lookup_level "provision/" 'dist.yml' "$PROVISION_USING" PROV_MODELS_LOOKUP_PATHS "$HOST_OS"
  u_autoload_add_lookup_level "provision/" "${HOST_TYPE}_host.dist.yml" "$PROVISION_USING" PROV_MODELS_LOOKUP_PATHS "$HOST_OS"

  u_autoload_add_lookup_level "provision/" "${INSTANCE_TYPE}.dist.yml" "$PROVISION_USING" PROV_MODELS_LOOKUP_PATHS "$HOST_OS"
  u_autoload_add_lookup_level "provision/" "${INSTANCE_TYPE}.${HOST_TYPE}_host.dist.yml" "$PROVISION_USING" PROV_MODELS_LOOKUP_PATHS "$HOST_OS"

  # TODO presets lookups.
}

##
# Gets a provisioning-related script path given a subject and an operation.
#
# It will look for any matching file and return the most "specific" one.
#
# @requires the following global in calling scope :
# - $PROVISION_USING
#
# @example
#   the_script=$(u_provisioning_get_script stack start)
#   . "$the_script"
#
u_provisioning_get_script() {
  local p_subject="$1"
  local p_operation="$2"
  local most_specific_match=''
  local script_lookup_path=''
  local script_lookup_paths=()

  u_autoload_add_lookup_level "cwt/$p_subject/" "${p_operation}.sh" "$PROVISION_USING" script_lookup_paths '' '/'
  for script_lookup_path in "${script_lookup_paths[@]}"; do
    if [[ -f "$script_lookup_path" ]]; then
      most_specific_match="$script_lookup_path"
    fi
  done

  echo "$most_specific_match"
}
