#!/usr/bin/env bash

##
# Bootstrap phase: source CWT_INC (eager *.inc.sh includes, override-aware).
#
# Sourced only from cwt/bootstrap.sh (inside CWT_BS_FLAG).
#
# @see cwt/bootstrap.sh
#

# Load additional includes (including extensions').
if [[ -n "$CWT_INC" ]]; then
  for file in $CWT_INC; do
    # Any additional include may be overridden.
    u_autoload_override "$file" 'continue'
    if [[ -n "$inc_override_evaled_code" ]]; then
      eval "$inc_override_evaled_code"
    fi
    if [[ -f "$file" ]]; then
      . "$file"
    fi
  done
fi
