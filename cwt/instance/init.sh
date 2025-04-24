#!/usr/bin/env bash

##
# Instance initialization process ("instance init").
#
# Uses env.yml files.
# @see u_instance_init() in cwt/instance/instance.inc.sh
#
# @example
#   # Calling this script without any arguments will use prompts in terminal
#   # to provide values for every globals.
#   cwt/instance/init.sh
#   # Or :
#   make init
#
#   # Initializes given stack version without prompts (i.e. default values) :
#   cwt/instance/init.sh -s 'myproject-2024' -y
#   # Or :
#   make init -- -s 'myproject-2024' -y
#
#   # Init with instance type = prod :
#   cwt/instance/init.sh -t 'prod' -y
#   # Or :
#   make init -- -t 'prod' -y
#
#   # Init with host type = remote :
#   cwt/instance/init.sh -h 'remote' -y
#   # Or :
#   make init -- -h 'remote' -y
#

# This action can be (re)launched after local instance was already initialized,
# and in this case, we cannot have 'readonly' variables automatically loaded
# during CWT bootstrap -> so we use that var as a flag to avoid it.
# @see cwt/bootstrap.sh
CWT_BS_SKIP_GLOBALS=1

. cwt/bootstrap.sh

u_instance_init $@
