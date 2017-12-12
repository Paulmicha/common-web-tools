#!/usr/bin/env bash

##
# Local file-based registry utility functions.
#
# @see cwt/env/registry/file.sh
#
# This file is dynamically loaded.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Generates a registry filepath from string.
#
# Requires $INSTANCE_DOMAIN env var, as it's used as default namespace.
# If the directory used to store files doesn't exist, it will be created.
#
# @param 1 String : the key identifying a registry entry.
# @param 2 String [optional] : the namespace to use for this registry entry.
#   Can be 'host' or any string. Default: $INSTANCE_DOMAIN.
#
# @see u_check_once() in cwt/env/registry/file.sh
#
u_file_registry_get_path() {
  local p_key="$1"
  local p_namespace="$2"

  local slug=$(u_slugify_u "$p_key")
  local reg_dir="/opt/cwt-registry/$INSTANCE_DOMAIN"

  if [[ -n "$p_namespace" ]]; then
    local namespace=$(u_slugify "$p_namespace")
    reg_dir="/opt/cwt-registry/$namespace"
  fi

  if [[ ! -d "$reg_dir" ]]; then
    mkdir -p "$reg_dir"
    # TODO error handling : break calling operation if dir creation failed.
  fi

  echo "$reg_dir/.$slug.env"
}
