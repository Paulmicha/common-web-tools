#!/usr/bin/env bash

##
# Implements hook -s 'instance' -a 'registry_set'.
#
# Uses the following vars in calling scope :
# - reg_key
# - reg_val
#
# @see u_instance_registry_set() in cwt/instance/instance.inc.sh
#

reg_file_path=''

u_file_registry_get_path "$reg_key"

echo "$reg_val" > "$reg_file_path"
