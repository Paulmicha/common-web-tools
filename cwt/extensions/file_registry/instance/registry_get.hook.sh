#!/usr/bin/env bash

##
# Implements hook -s 'instance' -a 'registry_get'.
#
# Uses the following vars in calling scope :
# - reg_key
#
# @see u_instance_registry_get() in cwt/instance/instance.inc.sh
#

reg_val=''
reg_file_path=''

u_file_registry_get_path "$reg_key"

if [ -f "$reg_file_path" ]; then
  reg_val=$(cat "$reg_file_path")
fi
