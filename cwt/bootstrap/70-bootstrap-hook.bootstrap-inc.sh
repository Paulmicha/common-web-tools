#!/usr/bin/env bash

##
# Bootstrap phase: trigger the bootstrap hook.
#
# Sourced only from cwt/bootstrap.sh (inside CWT_BS_FLAG).
#
# @see cwt/bootstrap.sh
#

# Allow extensions to implement custom additional env. variables.
hook -s 'cwt' -a 'bootstrap' -v 'STACK_VERSION PROVISION_USING'
