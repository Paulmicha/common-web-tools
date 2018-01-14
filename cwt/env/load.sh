#!/usr/bin/env bash

##
# Loads current environment vars and aliases.
#
# TODO [wip] Rename this file to implement u_hook 'cwt' 'bootstrap' instead.
#
# This script is idempotent (can be imported many times). Note: combined scripts
# may result in sourcing this file many times over, because for simplicity there
# is no verification preventing this from happening.
#
# Usage :
# . cwt/env/load.sh
#

if [[ ! -f "cwt/env/current/global.vars.sh" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: no global vars found." >&2
  echo "-> Run cwt/stack/init.sh first." >&2
  echo "Aborting (1)." >&2
  return 1
fi

# Load current instance env settings (globals) + ignore readonly errors.
# [wip] TODO use readonly globals.
. cwt/env/current/global.vars.sh
