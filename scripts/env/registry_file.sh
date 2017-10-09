#!/bin/bash

##
# Local file-based registry.
#
# These utilies allow to store values or secrets per user and per host in simple
# plain text files.
#
# Note : these functions are minimal implementations, please consider
# alternatives like Ansible Vault, Hashicorp Vault, etc.
#
# Convention : fonctions names are all prefixed by "u" (for "utility").
#
# Load from project root dir :
# . scripts/env/registry_file.sh
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
  local REG_FILE=$(u_file_registry_get_path "$1")
  if [ -f $REG_FILE ]; then
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

##
# Arbitrary string check against custom file-based registry path.
#
# Allows to verify if given call has already been run on current host with the
# current user. Useful for operations that should only run once per host(+user).
#
# Simply checks if an empty file named after a transformation of the string
# passed as argument exists in current user's home dir.
# Warning : the only transformation applied to the string passed as argument
# is u_slugify_u() in order to get a workable filename, so make sure the string
# is fit for that purpose. This may also lead to false positives.
#
# @see u_slugify_u()
#
# @param 1 String : Unsually the script path or function call, with or without
#   arguments. This could be anything, the point being uniquely identifying an
#   action so it is only run once per host (until the corresponding file "flag"
#   is deleted).
#
# @example
#   THIS_ABS_PATH=$(u_get_script_path ${BASH_SOURCE[0]})
#   if $(u_check_once "${THIS_ABS_PATH} arg"); then
#     echo "Proceed."
#   else
#     echo "Abort : this has already been run once."
#     return
#   fi
#
u_check_once() {
  local ONCE_FILE=$(u_file_registry_get_path "$1")

  if [ ! -f $ONCE_FILE ]; then
    touch $ONCE_FILE
    return
  fi

  false
}

##
# Generates a registry filepath from string.
#
# If the directory used to store files doesn't exist, it wil be created.
#
# @see u_check_once()
#
u_file_registry_get_path() {
  local SLUG=$(u_slugify_u "$1")
  local REG_PATH="$HOME/registry/$INSTANCE_DOMAIN"
  local REG_DIR="$REG_PATH/v1"

  if [ ! -d $REG_DIR ]; then
    mkdir -p $REG_DIR
  fi

  echo "$REG_DIR/.$SLUG.env"
}
