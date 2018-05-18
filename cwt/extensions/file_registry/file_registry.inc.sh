#!/usr/bin/env bash

##
# Local file-based registry utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Generates a registry filepath from string.
#
# @param 1 String : the key identifying a registry entry.
# @param 2 String [optional] : the namespace to use for this registry entry.
#   Can be 'host' or any string. Default: $INSTANCE_DOMAIN.
#
# @requires the following globals in calling scope :
#   - $INSTANCE_DOMAIN
#   - $FILE_REGISTRY_PATH
#
# If the directory used to store files doesn't exist, it will be created.
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to a variable subject to collision in calling scope.
#
# @var reg_file_path
#
# @example
#   # For current instance :
#   u_file_registry_get_path "$1"
#   echo "$reg_file_path" # <- Prints the path to the file where value is stored for given key.
#
#   # For entire host :
#   u_file_registry_get_path "$1" 'host'
#   echo "$reg_file_path" # <- Idem (see example above).
#
u_file_registry_get_path() {
  local p_key="$1"
  local p_namespace="$2"
  local slug

  slug=$(u_str_slug_u "$p_key")
  reg_file_path="$FILE_REGISTRY_PATH/$INSTANCE_DOMAIN"

  if [[ -n "$p_namespace" ]]; then
    local namespace
    namespace=$(u_str_slug "$p_namespace")
    reg_file_path="$FILE_REGISTRY_PATH/$namespace"

  # Cannot carry on without an INSTANCE_DOMAIN value here.
  elif [[ -z "$INSTANCE_DOMAIN" ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: the global 'INSTANCE_DOMAIN' cannot be empty." >&2
    echo "Have you run instance init (make) ?" >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  if [[ ! -d "$reg_file_path" ]]; then
    mkdir -p "$reg_file_path"

    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: failed to create file registry dir." >&2
      echo "Could be a permission error." >&2
      echo "-> Aborting (2)." >&2
      echo >&2
      exit 2
    fi
  fi

  reg_file_path+="/.${slug}.reg"
}
