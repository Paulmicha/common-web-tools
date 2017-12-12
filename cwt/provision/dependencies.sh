#!/usr/bin/env bash

##
# Provisions project dependencies.
#
# This script is meant to be called during stack setup. Unless we know what
# we're doing, we shouldn't have to call it directly.
# @see cwt/stack/setup.sh
#
# @requires cwt/stack/init.sh (must have already been run at least once).
#
# Usage :
# . cwt/provision/dependencies.sh
#

# First make sure we have the provision method available in this shell (scope).
if [[ -z "$PROVISION_USING" ]]; then
  echo
  echo "Error in $BASH_SOURCE line $LINENO: no provisioning method provided."
  echo "Aborting (1)."
  echo
  return 1
fi

# TODO Install dependencies.
# u_provisioning_install_deps
