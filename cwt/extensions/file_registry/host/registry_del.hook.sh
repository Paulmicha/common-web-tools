#!/usr/bin/env bash

##
# Implements hook -s 'host' -a 'registry_del'.
#
# Uses the following vars in calling scope :
# - reg_key
#
# @see u_host_registry_del() in cwt/host/host.inc.sh
#

reg_file_path=''

u_file_registry_get_path "$reg_key" 'host'

if [[ -f "$reg_file_path" ]]; then
  rm "$reg_file_path"
fi
