#!/usr/bin/env bash

##
# Bootstrap phase: load locally generated global env vars (if present).
#
# Sourced only from cwt/bootstrap.sh (inside CWT_BS_FLAG).
# Opt out with CWT_BS_SKIP_GLOBALS=1.
#
# @see cwt/bootstrap.sh
# @see cwt/instance/init.sh
#

# If instance init was run at least once, automatically load locally generated
# global env vars.
# This can be opted-out by setting the flag CWT_BS_SKIP_GLOBALS to 1.
# @see cwt/instance/init.sh
if [[ $CWT_BS_SKIP_GLOBALS -ne 1 ]]; then
  if [[ -f data/cwt/global.vars.sh ]]; then
    . data/cwt/global.vars.sh
  fi
fi
