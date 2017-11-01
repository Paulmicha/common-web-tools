#!/bin/bash

##
# Local file-based registry.
#
# These utilies allow to store values or secrets for this instance in simple
# plain text files.
#
# @requires cwt/utilities/registry/file.sh
#
# Note : these functions are minimal implementations, please consider
# alternatives like Ansible Vault, Hashicorp Vault, etc.
#
# Convention : fonctions names are all prefixed by "u" (for "utility").
#
# Load from project root dir :
# . cwt/env/registry/file.sh
#

##
# Reads a registry value (by key).
#
# @param 1 String : the key (or name) of the value to read.
#
# @example
#   VAL=$(u_registry_get_val 'key')
#   if [[ -z "$VAL" ]]; then
#     echo "Nothing in store."
#   else
#     echo "Value = $VAL"
#   fi
#
u_registry_get_val() {
  local reg_file=$(u_file_registry_get_path "$1")
  if [ -f $reg_file ]; then
    cat $(u_file_registry_get_path "$1")
  fi
}

##
# Writes a registry value (by key).
#
# @param 1 String : the key (or name) of the value to write.
# @param 2 String : the value.
#
# @example
#   u_registry_set_val 'key' 'value'
#
u_registry_set_val() {
  echo "$2" > $(u_file_registry_get_path "$1")
}
