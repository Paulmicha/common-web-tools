#!/bin/bash

##
# App instance installation.
#
# @prereq stack services must be running (stack/start).
#
# Usage from project root dir :
# $ . cwt/app/install.sh
#

. cwt/env/load.sh

# TODO make hooks work for single arg.
# P_VERBOSE=1
u_hook_app 'install' 'local'

# Allow custom complements for this script.
u_autoload_get_complement "$BASH_SOURCE"
