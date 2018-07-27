#!/usr/bin/env bash

##
# Implements hook -a 'ensure_dirs_exist' -s 'instance'.
#
# This file is dynamically included when the "hook" is triggered.
# @see u_instance_init() in cwt/instance/instance.inc.sh
#

if [[ ! -d "cwt/env/current/remote-instances" ]]; then
  echo "Creating required dir cwt/env/current/remote-instances"
  mkdir -p "cwt/env/current/remote-instances"
fi
