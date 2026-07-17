#!/usr/bin/env bash

##
# Implements hook -a 'ensure_dirs_exist' -s 'instance'.
#
# This file is dynamically included when the "hook" is triggered.
# @see u_instance_init() in cwt/instance/instance.inc.sh
#

if [[ ! -d "data/cwt/remote-instances" ]]; then
  echo "Creating required dir data/cwt/remote-instances"
  mkdir -p "data/cwt/remote-instances"
fi
