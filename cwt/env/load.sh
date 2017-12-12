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

if [[ ! -f "cwt/env/current/vars.sh" ]]; then
  echo
  echo "Error in $BASH_SOURCE line $LINENO: no env settings found."
  echo "-> Run cwt/stack/init.sh first."
  echo "Aborting (1)."
  return 1
fi

# Load current instance env settings (globals) + ignore readonly errors.
# [wip] TODO evaluate not requiring readonly globals.
# . cwt/env/current/vars.sh 2> /dev/null
. cwt/env/current/vars.sh

# Load global bash utils.
. cwt/bootstrap.sh

# TODO evaluate removing 'registry' feature.
. cwt/env/registry.sh

# Load bash aliases.
# NB: aliases are not expanded when the shell is not interactive, unless the
# expand_aliases shell option is set using shopt.
# See https://unix.stackexchange.com/a/1498
shopt -s expand_aliases

# TODO [wip] Refacto hooks to follow u_cwt_extend().
u_hook_app 'bash' 'alias'
