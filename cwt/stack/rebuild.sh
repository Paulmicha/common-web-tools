#!/bin/bash

##
# Rebuilds required services.
#
# @requires cwt/stack/setup.sh (must have already been run at least once).
#
# Run as root or sudo.
#
# Usage :
# $ . cwt/stack/rebuild.sh
#

. cwt/env/load.sh

. cwt/stack/stop.sh

# Execute the "rebuild" script corresponding to provisioning method.
# TODO use hook instead
# @see cwt/utilities/hook.sh
script="$(u_provisioning_get_script 'stack' 'rebuild')"
if [[ -f "$script" ]]; then
  . "$script"
fi

. cwt/stack/start.sh

# Allow custom complements for this script.
u_autoload_get_complement "$BASH_SOURCE"
