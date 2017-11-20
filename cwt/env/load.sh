#!/bin/bash

##
# Loads current environment vars and aliases.
#
# This script is idempotent (can be imported many times). Note: combined scripts
# may result in sourcing this file many times over, because for simplicity there
# is no verification preventing this from happening.
#
# Usage :
# . cwt/env/load.sh
#

if [ ! -f "cwt/env/current/vars.sh" ]; then
  echo
  echo "Error in $BASH_SOURCE line $LINENO: no env settings found."
  echo "-> Run cwt/stack/init.sh first."
  echo "Aborting (1)."
  return 1
fi

# Load current instance env settings (globals) + ignore readonly errors.
. cwt/env/current/vars.sh 2> /dev/null

# Load global bash utils and aliases.
. cwt/bash_utils.sh
. cwt/env/registry.sh
. cwt/aliases.sh
