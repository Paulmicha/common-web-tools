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

# Measure time elapsed.
SECONDS=0

# This allows to customize CWT extensibility.
export CWT_EXTENSIONS

# Include required utilities.
. cwt/utilities/autoload.sh
for file in $(find cwt/utilities/* -type f -print0 | xargs -0); do
  . "$file"
  u_autoload_get_complement "$file"
done

echo
echo "Seconds elapsed - include required utilities = $SECONDS"
echo

# Initializes hooks and lookups (CWT extension mecanisms).
u_cwt_extend

echo
echo "Seconds elapsed - u_cwt_extend = $SECONDS"
echo

# Load optional additional includes.
if [[ -n "$CWT_INC" ]]; then
  for file in $CWT_INC; do
    . "$file"
    u_autoload_get_complement "$file"
  done
fi

echo
echo "Seconds elapsed - optional additional includes = $SECONDS"
echo

# Call any 'bootstrap' hooks.
u_hook 'cwt' 'bootstrap'

echo
echo "Seconds elapsed - u_hook 'cwt' 'bootstrap' = $SECONDS"
echo
