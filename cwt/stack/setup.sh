#!/usr/bin/env bash

##
# Installs host-level dependencies.
#
# @requires cwt/stack/init.sh (must have already been run at least once).
#
# Run as root or sudo.
#
# Usage :
# $ . cwt/stack/setup.sh
#

. cwt/env/load.sh

# TODO use hook instead
# @see cwt/utilities/hook.sh
. cwt/provision/dependencies.sh


# Allow custom complements for this script.
u_autoload_get_complement "$BASH_SOURCE"
