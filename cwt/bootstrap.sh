#!/usr/bin/env bash

##
# Bootstraps CWT.
#
# Loads includes containing bash functions + call optional bootstrap hooks.
#
# TODO [wip] evaluating not resetting these globals on every call to bootstrap.
# This is to allow presets to be organized like the cwt folder (extensibility).
#
# @example
#   . cwt/bootstrap.sh
#

# Advanced usage : allows swapping global namespace at runtime. Used for
# exporting dynamic global variables names.
# NB : not every global is namespaced. The hardcoded ones are to be considered
# CWT internal globals.
# @see u_cwt_extend()
if [[ -z "$NAMESPACE" ]]; then
  export NAMESPACE='CWT'
fi

# Makes sure bootstrap runs once per namespace.
eval "once=\$${NAMESPACE}_BS_FLAG"
if [[ -z "$once" ]]; then
  eval "export ${NAMESPACE}_BS_FLAG=1"

  # Include required utilities.
  . cwt/utilities/autoload.sh # TODO include once (convenience).
  for file in $(find cwt/utilities/* -type f -print0 | xargs -0); do
    . "$file"
    u_autoload_get_complement "$file"
  done

  # TODO [wip] workaround instance state limitations (e.g. unhandled shutdown).
  u_instance_get_state

  # Initializes hooks and lookups (CWT extension mecanisms).
  u_cwt_extend

  # Load optional additional includes.
  if [[ -n "$CWT_INC" ]]; then
    for file in $CWT_INC; do
      . "$file"
      u_autoload_get_complement "$file"
    done
  fi

  # If stack init was run at least once, automatically load global env vars.
  if [[ -f "cwt/env/current/vars.sh" ]]; then
    . cwt/env/load.sh
  fi

  # Call any 'bootstrap' hooks.
  u_hook 'cwt' 'bootstrap'
fi
