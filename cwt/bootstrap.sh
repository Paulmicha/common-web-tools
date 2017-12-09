#!/bin/bash

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

# This allows to customize CWT extensibility.
export CWT_EXTENSIONS

# Include required utilities.
. cwt/utilities/autoload.sh
for file in $(find cwt/utilities/* -type f -print0 | xargs -0); do
  eval $(u_autoload_override "$file" 'continue')

  . "$file"

  u_autoload_get_complement "$file"
done

# Get CWT core "objects".
u_cwt_extend

# Load optional additional includes.
if [[ -n "$CWT_INC" ]]; then
  for file in $CWT_INC; do
    eval $(u_autoload_override "$file" 'continue')

    . "$file"

    u_autoload_get_complement "$file"
  done
fi

# Call any 'bootstrap' hooks.
u_hook 'cwt' 'bootstrap'
