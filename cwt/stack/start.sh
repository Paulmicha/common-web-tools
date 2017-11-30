#!/bin/bash

##
# Starts required services.
#
# @requires cwt/stack/setup.sh (must have already been run at least once).
#
# Run as root or sudo.
#
# Usage :
# $ . cwt/stack/start.sh
#

. cwt/env/load.sh

# Execute the "start" script corresponding to provisioning method.
# TODO use hook instead
# @see cwt/utilities/hook.sh
script="$(u_provisioning_get_script 'stack' 'start')"
if [[ -f "$script" ]]; then
  . "$script"
fi


# Allow custom complements for this script.
u_autoload_get_complement "$BASH_SOURCE"
