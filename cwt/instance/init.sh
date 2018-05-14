#!/usr/bin/env bash

##
# CWT instance init action.
#
# TODO [wip] document arguments.
# @see u_instance_init()
#
# @example
#   cwt/instance/init.sh
#

# This action can be (re)launched after local instance was already initialized,
# and in this case, we cannot have 'readonly' variables automatically loaded
# during CWT bootstrap -> so we use that var as a flag to avoid it.
# @see cwt/bootstrap.sh
CWT_BS_SKIP_GLOBALS=1

. cwt/bootstrap.sh

u_instance_init "$@"
